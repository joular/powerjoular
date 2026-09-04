--
--  Copyright (c) 2020-2026, Adel Noureddine.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Exceptions;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Ctrl_C;

with CPU_Load;
with Joular_Core;

with PowerJoular; use PowerJoular;
with PowerJoular.CSV;
with PowerJoular.Help;
with PowerJoular.Options; use PowerJoular.Options;
with PowerJoular.Ring_Buffer;
with PowerJoular.Terminal;
with PowerJoular.Virtual_Machine;

-- Read the command line, then measure the machine once a cycle until Ctrl+C, handing each cycle to the outputs asked for
procedure PowerJoular_Main is

    -- What the command line asked for
    Config : Settings;
    Result : Outcome;

    -- The hardware Joular Core is asked about, and what of it answered
    Sources : Joular_Core.Source_List;
    CPU_Available : Boolean := False;
    GPU_Available : Boolean := False;

    -- Set when Ctrl+C is pressed, so the loop below stops and the program ends on its own terms
    -- Volatile, as it is written while the loop is running
    Stop_Asked : Boolean := False;
    pragma Volatile (Stop_Asked);

    -- The two CPU load samples a cycle is worked out from, and the moment each of them was taken
    Before, After : CPU_Load.Sample;
    Taken_Before, Taken_After : Time;

    -- What the hardware reported this cycle
    Measurements : Joular_Core.Reading;

    -- The cycle handed to the outputs, and the total power of the previous one, which the terminal shows the change from
    Data : Cycle;
    Previous_Total_Power : Long_Float := 0.0;

    -- When the cycle being measured ends
    Deadline : Time;

    -- Set once a cycle went wrong, so the trouble is said once instead of every second
    Reported_A_Failure : Boolean := False;

    -- How long the cycle that just went by actually took, in seconds
    -- The clock is trusted here rather than the length asked for, as a machine under load runs late
    Elapsed : Duration;

    --------------------------------------------------

    -- Called when Ctrl+C is pressed
    -- It only asks the loop to stop: printing, writing files or reading the hardware is not safe to do from a handler
    procedure On_Ctrl_C is
    begin
        Stop_Asked := True;
    end On_Ctrl_C;

    --------------------------------------------------

    -- One hardware measurement turned into watts
    -- Some hardware reports the joules spent since the previous reading, some reports the watts it is drawing
    function Watts (Value : in Joular_Core.Measurement; Over : in Duration) return Long_Float is
    begin
        if not Value.Available then
            return 0.0;
        end if;

        case Value.Unit is
            when Joular_Core.Power =>
                return Value.Value;

            when Joular_Core.Energy =>
                if Over <= 0.0 then
                    return 0.0;
                end if;

                return Value.Value / Long_Float (Over);
        end case;
    end Watts;

    --------------------------------------------------

    -- One CPU load sample of whatever is being monitored
    -- The same sample carries the load of the machine and the load of the process or application, when there is one
    function Take_Sample return CPU_Load.Sample is
    begin
        case Config.Target is
            when Whole_System =>
                return CPU_Load.Take;

            when One_Process =>
                return CPU_Load.Take (Config.PID);

            when One_Application =>
                return CPU_Load.Take (To_String (Config.App));
        end case;
    end Take_Sample;

    --------------------------------------------------

    -- Wait for the cycle to end, waking up along the way so a Ctrl+C is noticed at once instead of a cycle later
    procedure Wait_Until (Ending : in Time) is
        Step : constant Time_Span := Milliseconds (100);
        Next : Time := Clock + Step;
    begin
        while not Stop_Asked and then Next < Ending loop
            delay until Next;
            Next := Next + Step;
        end loop;

        if not Stop_Asked then
            delay until Ending;
        end if;
    end Wait_Until;

    --------------------------------------------------

begin
    Terminal.Enable_Escape_Sequences;

    Parse (Config, Result);

    case Result is
        when Finished =>
            return;

        when Rejected =>
            Set_Exit_Status (Failure);
            return;

        when Run =>
            null;
    end case;

    -- Stop cleanly on Ctrl+C, instead of being cut down where it stands
    -- Unrestricted_Access is needed as the handler is declared inside this procedure rather than on its own
    GNAT.Ctrl_C.Install_Handler (On_Ctrl_C'Unrestricted_Access);

    -- Inside a virtual machine the processor can't be measured, so the host writes its power to a file instead
    -- The graphic card is still worth asking about, as it may have been passed through to the machine
    Sources := (Joular_Core.CPU => not Config.Read_VM, Joular_Core.GPU => True);
    Joular_Core.Open (Sources);

    -- The first sample and a first reading, thrown away: the reading says what the machine has to offer,
    -- and it marks the point the energy counters of the first cycle are counted from
    -- They are taken in the order the loop below takes them, and nothing is allowed in between: whatever
    -- time passes between the two ends up counted in the first cycle without being measured in it
    Before := Take_Sample;
    Taken_Before := Clock;
    Measurements := Joular_Core.Read (Sources);

    CPU_Available := Measurements (Joular_Core.CPU).Available;
    GPU_Available := Measurements (Joular_Core.GPU).Available;

    Deadline := Taken_Before + To_Time_Span (Cycle_Interval);

    if Config.Write_Ring_Buffer and then not Ring_Buffer.Open then
        Put_Line (Standard_Error,
                  "powerjoular: cannot open the ring buffer at " & Ring_Buffer.Path
                  & ", the monitoring goes on without it.");
        Config.Write_Ring_Buffer := False;
    end if;

    if Config.Show_Debug then
        Help.Show_System_Info
            (CPU_Available => CPU_Available,
             GPU_Available => GPU_Available,
             Ring_Buffer_Path => Ring_Buffer.Path,
             Using_Ring_Buffer => Config.Write_Ring_Buffer);
    end if;

    -- Nothing at all to measure, which is worth saying rather than writing zeroes for hours on end
    if not Config.Read_VM and then not CPU_Available and then not GPU_Available then
        Put_Line (Standard_Error, "powerjoular: no power source found on this machine.");
#if PJ_MACOS then
        Put_Line (Standard_Error,
                  "On a Mac, reading powermetrics needs root: try 'sudo powerjoular'.");
        Put_Line (Standard_Error,
                  "Only the Macs with an Apple Silicon chip are supported, the ones with an Intel processor are not.");
#elsif PJ_WINDOWS then
        -- Nothing is installed and no rights are asked for on a machine where Energy Meter Interface (EMI) is used which is shipped by default in Windows 11
        Put_Line (Standard_Error,
                  "On Windows, Energy Meter Interface (EMI) was not found or does not measure the processor.");
        Put_Line (Standard_Error,
                  "Install the PawnIO driver (https://pawnio.eu) and run this from a terminal with administrative rights, or Hubblo's RAPL driver, which doesn't requires admin rights.");
#else
        Put_Line (Standard_Error,
                  "On a PC or a server, reading RAPL needs root: try 'sudo powerjoular'.");
#end if;
        Ring_Buffer.Close;
        Joular_Core.Close;
        Set_Exit_Status (Failure);
        return;
    end if;

    while not Stop_Asked loop
        Wait_Until (Deadline);
        exit when Stop_Asked;

        -- One bad cycle, a power source that stops answering or a process that goes away mid-reading,
        -- should not bring down a run that has been going for hours
        begin
            -- The load and the hardware are read back to back, so both cover the same stretch of time
            After := Take_Sample;
            Taken_After := Clock;
            Measurements := Joular_Core.Read (Sources);

            Elapsed := To_Duration (Taken_After - Taken_Before);

            Data := (others => <>);
            Data.CPU_Usage := CPU_Load.System_Usage (Before, After);

            if Config.Target /= Whole_System then
                Data.Target_Usage := CPU_Load.Process_Usage (Before, After);
            end if;

            Before := After;
            Taken_Before := Taken_After;

            -- Where the power of the processor comes from: the file the host writes when inside a virtual machine,
            -- the hardware itself everywhere else
            if Config.Read_VM then
                Data.CPU_Power :=
                    Virtual_Machine.Power
                        (File_Name => To_String (Config.VM_File),
                         Format => To_String (Config.VM_Format));
            else
                Data.CPU_Power := Watts (Measurements (Joular_Core.CPU), Elapsed);
            end if;

            Data.GPU_Power := Watts (Measurements (Joular_Core.GPU), Elapsed);
            Data.Total_Power := Data.CPU_Power + Data.GPU_Power;

            -- The power of the processor shared out in proportion to how much of the machine the process took
            if Data.CPU_Usage > 0.0 then
                Data.Target_Power := Long_Float'Min (Data.CPU_Power, Data.CPU_Power * Data.Target_Usage / Data.CPU_Usage);
            end if;

            if Config.Show_Terminal then
                Terminal.Show
                    (Data => Data,
                     Target => Config.Target,
                     Previous_Total_Power => Previous_Total_Power,
                     GPU_Available => GPU_Available);
            end if;

            if Config.Write_CSV then
                CSV.Save_System
                    (Filename => To_String (Config.CSV_File),
                     Data => Data,
                     Overwrite => Config.Overwrite);

                if Config.Target /= Whole_System then
                    CSV.Save_Target
                        (Filename => Target_CSV_File (Config),
                         Data => Data,
                         Overwrite => Config.Overwrite);
                end if;
            end if;

            if Config.Write_Ring_Buffer then
                Ring_Buffer.Write (Data);
            end if;

            Previous_Total_Power := Data.Total_Power;
        exception
            when others =>
                if not Reported_A_Failure then
                    Reported_A_Failure := True;
                    Put_Line (Standard_Error,
                              "powerjoular: a measurement could not be taken, the monitoring goes on.");
                end if;
        end;

        Deadline := Deadline + To_Time_Span (Cycle_Interval);

        -- A machine that went to sleep, or one that fell badly behind, leaves the deadline in the past
        -- Starting again from now keeps the cycles a second apart instead of racing to catch up
        if Deadline < Clock then
            Deadline := Clock + To_Time_Span (Cycle_Interval);
        end if;
    end loop;

    if Config.Show_Terminal then
        Terminal.Close_Line;
    end if;

    Ring_Buffer.Close;
    Joular_Core.Close;

    -- Whatever goes wrong, the hardware is handed back and the ring buffer is unmapped before leaving
exception
    when E : others =>
        Put_Line (Standard_Error, "powerjoular: stopped on an unexpected error.");
        Put_Line (Standard_Error, Ada.Exceptions.Exception_Information (E));
        Ring_Buffer.Close;
        Joular_Core.Close;
        Set_Exit_Status (Failure);
end PowerJoular_Main;
