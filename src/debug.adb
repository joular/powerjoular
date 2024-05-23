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

package body Debug is

    procedure Save_Debug (Debug_Data : String) is
        F : File_Type; -- File handle
        Now : Time := Clock; -- Current UTC time

         -- Procedure to save data to file
        procedure Save_Data (F : File_Type) is
        begin
            Put (F, Image (Date => Now, Time_Zone => UTC_Time_Offset) & ","); -- Get time based on current timezone with UTC offset
            Put (F, Debug_Data);
            New_Line (F);
        end Save_Data;
    begin
        -- Append new data to the file
        Open (F, Append_File, "debug.log");
        Save_Data (F);
        Close (F);
    exception
        when Name_Error =>
            -- If failed to open file (happens on first time if file doesn't exist), then create it
            Create (F, Out_File, "debug.log");
            Put_Line (F, "");
            Save_Data (F);
            Close (F);
        when others =>
            raise PROGRAM_ERROR with "Error in accessing or creating the debug file";
    end;

end Debug;