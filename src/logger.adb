--
--  Copyright (c) 2020-2025, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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
with Ada.Calendar.Formatting; use Ada.Calendar.Formatting;

package body Logger is

    procedure Init (Log_File : String := "") is
    begin
        if Log_File /= "" then
            -- File name given, so log to file
            Create (Log_Output, Out_File, Log_File);
            Log_To_File := True;
        else
            -- No file given, so log to the terminal
            Log_To_File := False;
        end if;
    end Init;
   
    function Get_Time_Now return String is
        T : Time := Clock;
    begin
        return Image(T);
    end Get_Time_Now;
   
    function Level_To_String (Level : Log_Level) return string is
    begin
        case Level is
            when Debug => return "DEBUG";
            when Info  => return "INFO ";
            when Warn  => return "WARN ";
            when Error => return "ERROR";
        end case;
    end Level_To_String;
    
    procedure Log (Level : Log_Level; Message : String) is
        Line : constant String := "[" & Get_Time_Now & "] [" & Level_To_String (Level) & "] " & Message;
    begin
        if Log_To_File then
            Put_Line (Log_Output, Line);
        else
            Put_Line (Line);
        end if;
    end Log;
   
    procedure Close is
    begin
        if Log_To_File and then Is_Open (Log_Output) then
            Close (Log_Output);
        end if;
    end Close;

end Logger;
