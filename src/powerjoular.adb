--
--  Copyright (c) 2020-2024, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Float_Text_IO; use Ada.Long_Float_Text_IO;
with GNAT.Command_Line; use GNAT.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with GNAT.Ctrl_C; use GNAT.Ctrl_C;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Command_Line; use Ada.Command_Line;

with CPU_Cycles; use CPU_Cycles;
with CSV_Power; use CSV_Power;
with Help_Info; use Help_Info;
with CPU_STAT_PID; use CPU_STAT_PID;
with Intel_RAPL_sysfs; use Intel_RAPL_sysfs;
with OS_Utils; use OS_Utils;
with Nvidia_SMI; use Nvidia_SMI;
with Raspberry_Pi_CPU_Formula; use Raspberry_Pi_CPU_Formula;
with CPU_STAT_App; use CPU_STAT_App;
with Virtual_Machine; use Virtual_Machine;

procedure Powerjoular is
    -- Power variables
    --
    -- CPU Power
    CPU_Power : Long_Float; -- Entire CPU power consumption
    Previous_CPU_Power : Long_Float := 0.0; -- Previous CPU power consumption (t - 1)
    PID_CPU_Power : Long_Float; -- CPU power consumption of monitored PID
    App_CPU_Power : Long_Float; -- CPU power consumption of monitored application
    CPU_Energy : Long_Float := 0.0;
    --
    -- GPU Power
    GPU_Power : Long_Float := 0.0;
    Previous_GPU_Power : Long_Float := 0.0; -- Previous GPU power consumption (t - 1)
    GPU_Energy : Long_Float := 0.0;
    --
    -- Total Power and Energy
    Previous_Total_Power : Long_Float := 0.0; -- Previous entire total power consumption (t - 1)
    Total_Power : Long_Float := 0.0; -- Total power consumption of all hardware components
    Total_Energy : Long_Float := 0.0; -- Total energy consumed since start of PowerJoular until exit

    -- Data types for Intel RAPL energy monitoring
    RAPL_Before : Intel_RAPL_Data; -- Intel RAPL data
    RAPL_After : Intel_RAPL_Data; -- Intel RAPL data
    RAPL_Energy : Long_Float; -- Intel RAPL energy difference for monitoring cycle

    -- Data types for Nvidia energy monitoring
    Nvidia_Supported : Boolean; -- If nvidia card, drivers and smi tool are available

    -- Raspberrry Pi model settings
    Algorithm_Name : Unbounded_String := To_Unbounded_String ("polynomial"); -- Regression model type (by default, polynomial regression model)

    -- Data types to monitor CPU cycles
    CPU_CCI_Before : CPU_Cycles_Data; -- Entire CPU cycles
    CPU_CCI_After : CPU_Cycles_Data; -- Entire CPU cycles
    CPU_PID_Monitor : CPU_STAT_PID_Data; -- Monitored PID CPU cycles and power
    CPU_App_Monitor : CPU_STAT_App_Data; -- Monitored App CPU cycles and power

    -- CPU utilization variables
    CPU_Utilization : Long_Float; -- Entire CPU utilization
    PID_CPU_Utilization : Long_Float; -- CPU utilization of monitored PID
    App_CPU_Utilization : Long_Float; -- CPU utilization of monitored application

     -- OS name
    OS_Name : String := Get_OS_Name;

    -- Platform name
    Platform_Name : String := Get_Platform_Name;

   -- CSV filenames
   CSV_Filename                  :
      Unbounded_String; -- CSV filename for entire CPU power data
   PID_Or_App_CSV_Filename       :
      Unbounded_String; -- CSV filename for monitored PID or application CPU power data
   VM_File_Name                  : Unbounded_String;
   VM_Power_Format               : Unbounded_String;
   Read_File_Power_Joular_Format : Boolean := False;
   Read_File_Single_Cell_Format  : Boolean := False;
   Monitor_VM                    : Boolean := False;
   VM_Consumption                : Long_Float   := 0.0;
   Last_CPU_Power                : Float;
   Headers                       : Unbounded_String;

    -- Settings
    Show_Terminal : Boolean := False; -- Show power data on terminal
    Show_Debug : Boolean := False; -- Show debug info on terminal
    Print_File: Boolean := False; -- Save power data in file
    Monitor_PID : Boolean := False; -- Monitor a specific PID
    Monitor_App : Boolean := False; -- Monitor a specific application by its name
    Overwrite_Data : Boolean := false; -- Overwrite data instead of append on file

    -- Procedure to capture Ctrl+C to show total energy on exit
    procedure CtrlCHandler is
    begin
        New_Line;
        Put_Line ("--------------------------");
        Put ("Total energy: ");
        Put (Total_Energy, Exp => 0, Fore => 0, Aft => 2);
        Put_Line (" Joules, including:");
        Put (HT & "CPU energy: ");
        Put (CPU_Energy, Exp => 0, Fore => 0, Aft => 2);
        Put_Line (" Joules");
        Put (HT & "GPU energy: ");
        Put (GPU_Energy, Exp => 0, Fore => 0, Aft => 2);
        Put_Line (" Joules");
        Put_Line ("--------------------------");
        OS_Exit (0);
    end CtrlCHandler;

begin
    -- Capture Ctrl+C and redirect to handler
    Install_Handler(Handler => CtrlCHandler'Unrestricted_Access);

    -- Default CSV filename
    CSV_Filename := To_Unbounded_String ("./powerjoular-power.csv");

    -- Loop over command line options
    loop
      case Getopt ("h v t d f: p: a: o: u l m: s:") is
          when 'h' => -- Show help
              Show_Help;
              return;
          when 'v' => -- Show help
              Show_Version;
              return;
          when 't' => -- Show power data on terminal
              Show_Terminal := True;
          when 'd' => -- Show debug info on terminal
              Show_Debug := True;
          when 'p' => -- Monitor a particular PID
              -- PID_Number := Integer'Value (Parameter);
              CPU_PID_Monitor.PID_Number := Integer'Value (Parameter);
              Monitor_PID                := True;
          when 'a' => -- Monitor a particular application by its name
              CPU_App_Monitor.App_Name :=
                 To_Unbounded_String (Parameter);
              Monitor_App              := True;
          when 'f' => -- Specifiy a filename for CSV file (append data)
              CSV_Filename := To_Unbounded_String (Parameter);
              Print_File   := True;
          when 'o' => -- Specifiy a filename for CSV file (overwrite data)
              CSV_Filename   := To_Unbounded_String (Parameter);
              Print_File     := True;
              Overwrite_Data := True;
          when 'l' => -- Use linear regression model instead of polynomial models
              Algorithm_Name := To_Unbounded_String ("linear");
          when 'm' => -- Specify a filename for CSV file to be read
              VM_File_Name := To_Unbounded_String (Parameter);
              Monitor_VM := True;
          when 's' => -- Specify a filename for CSV file to be read
              VM_Power_Format := To_Unbounded_String (Parameter);
              Monitor_VM := True;
          when others =>
              exit;
      end case;
    end loop;

    if (Argument_Count = 0) then
        Show_Terminal := True;
    end if;

    -- If platform not supported, then exit program
    if (Platform_Name = "") then
        Put_Line ("Platform not supported");
        Put_Line (OS_Name);
        return;
    end if;

    if Show_Debug then
        Put_Line ("System info:");
        Put_Line (Ada.Characters.Latin_1.HT & "Platform: " & Platform_Name);
    end if;

    if Check_Intel_Supported_System (Platform_Name) then
        -- For Intel RAPL, check and populate supported packages first
        Check_Supported_Packages (RAPL_Before, "psys");

        if RAPL_Before.psys_supported then
            Get_Max_Energy_Range (RAPL_Before, "psys");
            if Show_Debug then
                Put_Line (Ada.Characters.Latin_1.HT & "Intel RAPL psys: " & Boolean'Image (RAPL_Before.Psys_Supported));
            end if;
        end if;

        if (not RAPL_Before.psys_supported) then -- Only check for pkg and dram if psys is not supported
            Check_Supported_Packages (RAPL_Before, "pkg");
            Check_Supported_Packages (RAPL_Before, "dram");
            if RAPL_Before.Pkg_Supported then
                Get_Max_Energy_Range (RAPL_Before, "pkg");
                if Show_Debug then
                    Put_Line (Ada.Characters.Latin_1.HT & "Intel RAPL pkg: " & Boolean'Image (RAPL_Before.pkg_supported));
                end if;
            end if;
            if RAPL_Before.Dram_Supported then
                Get_Max_Energy_Range (RAPL_Before, "dram");
                if Show_Debug then
                    Put_Line (Ada.Characters.Latin_1.HT & "Intel RAPL dram: " & Boolean'Image (RAPL_Before.Dram_Supported));
                end if;
            end if;
        end if;
        RAPL_After := RAPL_Before; -- Populate the "after" data type with same checking as the "before" (insteaf of wasting redundant calls to procedure)

        -- Check if Nvidia card is supported
        -- For now, Nvidia support requiers a PC/server, thus Intel support
        Nvidia_Supported := Check_Nvidia_Supported_System;
        if Nvidia_Supported and Show_Debug then
            Put_Line (Ada.Characters.Latin_1.HT & "Nvidia supported: " & Boolean'Image (Nvidia_Supported));
        end if;
    end if;

    -- Amend PID CSV file with PID number
    if Monitor_PID then
        PID_Or_App_CSV_Filename := CSV_Filename & "-" & Trim(Integer'Image (CPU_PID_Monitor.PID_Number), Ada.Strings.Left) & ".csv";
        if Show_Debug then
            Put_Line ("Monitoring PID: " & Integer'Image (CPU_PID_Monitor.PID_Number));
        end if;
    end if;

    -- Amend App CSV file with App name
    if Monitor_App then
        PID_Or_App_CSV_Filename := CSV_Filename & "-" & CPU_App_Monitor.App_Name & ".csv";
        if Show_Debug then
            Put_Line ("Monitoring application: " & To_String (CPU_App_Monitor.App_Name));
        end if;
    end if;

    -- Main monitoring loop
    loop
        -- Get a first snapshot of current entire CPU cycles
        Calculate_CPU_Cycles (CPU_CCI_Before);
        if Monitor_PID then -- Do the same for CPU cycles of the monitored PID
            Calculate_PID_Time (CPU_PID_Monitor, True);
        end if;

        if Monitor_App then -- Do the same for CPU cycles of the monitored application
            -- First update the PID array for the application
            -- We do it every cycle so PID list is always current and accurate
            Update_PID_Array (CPU_App_Monitor);
            Calculate_App_Time (CPU_App_Monitor, True);
        end if;

        if Check_Intel_Supported_System (Platform_Name) then
            -- Get a first snapshot of Intel RAPL energy data
            Calculate_Energy (RAPL_Before);
        end if;

        -- Wait for 1 second
        delay 1.0;

        -- Get a second snapshot of current entire CPU cycles
        Calculate_CPU_Cycles (CPU_CCI_After);
        if Monitor_PID then -- Do the same for CPU cycles of the monitored PID
            Calculate_PID_Time (CPU_PID_Monitor, False);
        end if;

        if Monitor_App then -- Do the same for CPU cycles of the monitored application
            Calculate_App_Time (CPU_App_Monitor, False);
        end if;

        if Check_Intel_Supported_System (Platform_Name) then
            -- Get a first snapshot of Intel RAPL energy data
            Calculate_Energy (RAPL_After);
        end if;

        -- Calculate entire CPU utilization
        CPU_Utilization := (Long_Float (CPU_CCI_After.cbusy) - Long_Float (CPU_CCI_Before.cbusy)) / (Long_Float (CPU_CCI_After.ctotal) - Long_Float (CPU_CCI_Before.ctotal));

        --Ajouter Test VM
      if Monitor_VM then
        --Put_Line ("VM Consumption : " & Float'Image(Calculate_VM_Consumption(VM_File_Name, VM_Power_Format)));
        CPU_Power := Long_Float(Calculate_VM_Consumption(VM_File_Name, VM_Power_Format));
        --CPU Power = Calculate
      else
          if Check_Raspberry_Pi_Supported_System (Platform_Name) then
              -- Calculate power consumption for Raspberry
              CPU_Power   :=
                 Calculate_CPU_Power
                    (CPU_Utilization, Platform_Name,
                     To_String (Algorithm_Name));
              Total_Power := CPU_Power;
          end if;

          if Check_Intel_Supported_System (Platform_Name) then
              -- Calculate Intel RAPL energy consumption
              RAPL_Energy :=
                 RAPL_After.total_energy - RAPL_Before.total_energy;

              if RAPL_Before.total_energy > RAPL_After.total_energy then
                  -- energy has wrapped
                  if RAPL_Before.psys_supported then
                      RAPL_Energy :=
                         RAPL_Energy + RAPL_Before.psys_max_energy_range;
                  elsif RAPL_Before.pkg_supported then
                      RAPL_Energy :=
                         RAPL_Energy + RAPL_Before.pkg_max_energy_range;
                  end if;
              end if;

              if RAPL_Before.pkg_supported and RAPL_Before.dram_supported
              then
                  if RAPL_Before.dram > RAPL_After.dram then
                      -- dram has wrapped
                      RAPL_Energy :=
                         RAPL_Energy + RAPL_Before.dram_max_energy_range;
                  end if;
              end if;

              CPU_Power   := RAPL_Energy;
              Total_Power := CPU_Power;
          end if;

      end if;

        if Nvidia_Supported then
            -- Calculate GPU power consumption
            GPU_Power := Get_Nvidia_SMI_Power;
            -- Add GPU power to total power
            -- The total power displayed by PowerJoular is therefore : CPU + GPU power
            Total_Power := Total_Power + GPU_Power;
        end if;

        -- If a particular PID is monitored, calculate its CPU time, CPU utilization and CPU power
        if Monitor_PID then
            PID_CPU_Utilization := (Long_Float (CPU_PID_Monitor.Monitored_Time)) / (Long_Float (CPU_CCI_After.ctotal) - Long_Float (CPU_CCI_Before.ctotal));
            PID_CPU_Power := (PID_CPU_Utilization * CPU_Power) / CPU_Utilization;

            -- Show CPU power data on terminal of monitored PID
            if Show_Terminal then
                Show_On_Terminal_PID (PID_CPU_Utilization, PID_CPU_Power, CPU_Utilization, CPU_Power, True);
            end if;

            -- Save CPU power data to CSV file of monitored PID
            if Print_File then
                Save_PID_To_CSV_File (To_String (PID_Or_App_CSV_Filename), PID_CPU_Utilization, PID_CPU_Power, Overwrite_Data);
            end if;
        end if;

        -- If a particular application is monitored, calculate its CPU time, CPU utilization and CPU power
        if Monitor_App then
            -- PID_Time := CPU_PID_After.total_time - CPU_PID_Before.total_time;
            App_CPU_Utilization := (Long_Float (CPU_App_Monitor.Monitored_Time)) / (Long_Float (CPU_CCI_After.ctotal) - Long_Float (CPU_CCI_Before.ctotal));
            App_CPU_Power := (App_CPU_Utilization * CPU_Power) / CPU_Utilization;

            -- Show CPU power data on terminal of monitored PID
            if Show_Terminal then
                Show_On_Terminal_PID (App_CPU_Utilization, App_CPU_Power, CPU_Utilization, CPU_Power, False);
            end if;

            -- Save CPU power data to CSV file of monitored PID
            if Print_File then
                Save_PID_To_CSV_File (To_String (PID_Or_App_CSV_Filename), App_CPU_Utilization, App_CPU_Power, Overwrite_Data);
            end if;
        end if;

        -- Show total power data on terminal
        if Show_Terminal and then (not Monitor_PID) and then (not Monitor_App) then
            Show_On_Terminal (CPU_Utilization, Total_Power, Previous_Total_Power, CPU_Power, GPU_Power, Nvidia_Supported);
        end if;

        Previous_CPU_Power := CPU_Power;
        Previous_GPU_Power := GPU_Power;
        Previous_Total_Power := Total_Power;

        -- Increment total energy with power of current cycle
        -- Cycle is 1 second, so energy for 1 sec = power
        Total_Energy := Total_Energy + Total_Power;
        CPU_Energy := CPU_Energy + CPU_Power;
        GPU_Energy := GPU_Energy + GPU_Power;

        -- Save total power data to CSV file
        if Print_File then
            Save_To_CSV_File (To_String (CSV_Filename), CPU_Utilization, Total_Power, CPU_Power, GPU_Power, Overwrite_Data);
        end if;
    end loop;
end Powerjoular;
