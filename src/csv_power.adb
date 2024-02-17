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
with Ada.Calendar; use Ada.Calendar;
with Ada.Long_Float_Text_IO; use Ada.Long_Float_Text_IO;
with Ada.Calendar.Formatting; use Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones; use Ada.Calendar.Time_Zones;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package body CSV_Power is

    procedure Save_To_CSV_File (Filename : String; Utilization : Long_Float; Total_Power : Long_Float; CPU_Power : Long_Float; GPU_Power : Long_Float; Overwrite_Data : Boolean) is
        F : File_Type; -- File handle
        Now : Time := Clock; -- Current UTC time

        -- Procedure to save data to file
        procedure Save_Data (F : File_Type) is
        begin
            Put (F, Image (Date => Now, Time_Zone => UTC_Time_Offset) & ","); -- Get time based on current timezone with UTC offset
            Put (F, Utilization, Exp => 0, Fore => 0); -- Exp = 0 to not show in scientific notation. Fore = 0 to show all digits
            Put (F, ",");
            Put (F, Total_Power, Exp => 0, Fore => 0);
            Put (F, ",");
            Put (F, CPU_Power, Exp => 0, Fore => 0);
            Put (F, ",");
            Put (F, GPU_Power, Exp => 0, Fore => 0);
            New_Line (F);
        end Save_Data;
    begin
        if Overwrite_Data then
            -- Overwrite each line of data on the file
            Open (F, Out_File, Filename);
        else
            -- Append new data to the file
            Open (F, Append_File, Filename);
        end if;
        Save_Data (F);
        Close (F);
    exception
        when Name_Error =>
            -- If failed to open file (happens on first time if file doesn't exist), then create it
            Create (F, Out_File, Filename);
            Put_Line (F, "Date,CPU Utilization,Total Power,CPU Power,GPU Power");
            Save_Data (F);
            Close (F);
        when others =>
            raise PROGRAM_ERROR with "Error in accessing or creating the CSV file";
    end;

    procedure Save_PID_To_CSV_File (Filename : String; Utilization : Long_Float; Power : Long_Float; Overwrite_Data : Boolean) is
        F : File_Type; -- File handle
        Now : Time := Clock; -- Current UTC time

        -- Procedure to save data to file
        procedure Save_Data (F : File_Type) is
        begin
            Put (F, Image (Date => Now, Time_Zone => UTC_Time_Offset) & ","); -- Get time based on current timezone with UTC offset
            Put (F, Utilization, Exp => 0, Fore => 0); -- Exp = 0 to not show in scientific notation. Fore = 0 to show all digits
            Put (F, ",");
            Put (F, Power, Exp => 0, Fore => 0);
            New_Line (F);
        end Save_Data;
    begin
        if Overwrite_Data then
            -- Overwrite each line of data on the file
            Open (F, Out_File, Filename);
        else
            -- Append new data to the file
            Open (F, Append_File, Filename);
        end if;
        Save_Data (F);
        Close (F);
    exception
        when Name_Error =>
            -- If failed to open file (happens on first time if file doesn't exist), then create it
            Create (F, Out_File, Filename);
            Put_Line (F, "Date,CPU Utilization,CPU Power");
            Save_Data (F);
            Close (F);
        when others =>
            raise PROGRAM_ERROR with "Error in accessing or creating the CSV file";
    end;

    procedure Show_On_Terminal (Utilization : Long_Float; Power : Long_Float; Previous_Power : Long_Float; CPU_Power : Long_Float; GPU_Power : Long_Float; GPU_Supported : Boolean) is
        Utilization_Percentage : Long_Float;
        Power_Difference : Long_Float;
    begin
        Utilization_Percentage := Utilization * 100.0;
        Put (CR);
        Put ("Total Power: ");
        Put (Power, Exp => 0, Fore => 0, Aft => 2);
        Put (" Watts ");
        Put ("(CPU: ");
        Put (CPU_Power, Exp => 0, Fore => 0, Aft => 2);
        Put (" W");

        if (GPU_Supported) then
            Put (", GPU: ");
            Put (GPU_Power, Exp => 0, Fore => 0, Aft => 2);
            Put (" W)" & HT);
        else
            Put (")" & HT);
        end if;

        Power_Difference := Power - Previous_Power;
        if (Power_Difference >= 0.0) then
            Put ("/\ ");
            Put (Power_Difference, Exp => 0, Fore => 0, Aft => 2);
            Put (" Watts");
        else
            Put ("\/ ");
            Put (Power_Difference, Exp => 0, Fore => 0, Aft => 2);
            Put (" Watts");
        end if;
    end;

    procedure Show_On_Terminal_PID (PID_Utilization : Long_Float; PID_Power : Long_Float; Utilization : Long_Float; Power : Long_Float; Is_PID : Boolean) is
        Utilization_Percentage : Long_Float;
        PID_Utilization_Percentage : Long_Float;
    begin
        Utilization_Percentage := Utilization * 100.0;
        PID_Utilization_Percentage := PID_Utilization * 100.0;
        Put (CR);
        if (Is_PID) then
            Put ("PID monitoring:" & HT & "CPU: ");
        else
            Put ("Application monitoring:" & HT & "CPU: ");
        end if;
        Put (PID_Utilization_Percentage, Exp => 0, Fore => 0, Aft => 2);
        Put (" % (");
        Put (Utilization_Percentage, Exp => 0, Fore => 0, Aft => 2);
        Put (" %)" & HT);
        Put (PID_Power, Exp => 0, Fore => 0, Aft => 2);
        Put (" Watts (");
        Put (Power, Exp => 0, Fore => 0, Aft => 2);
        Put (" Watts)");
    end;

end CSV_Power;
