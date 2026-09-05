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

with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Text_IO; use Ada.Text_IO;

with PowerJoular.Formatting; use PowerJoular.Formatting;

package body PowerJoular.CSV is

    -- How many digits are kept after the dot
    Load_Decimals : constant := 4;
    Power_Decimals : constant := 4;

    -- The files that could not be written to, so each one is reported once and on its own name
    -- Monitoring a process writes two files, and trouble with one of them says nothing about the other
    package Name_Sets is new Ada.Containers.Indefinite_Ordered_Sets (String);

    Reported : Name_Sets.Set;

    --------------------------------------------------

    -- Add one row to the file, and create it if not exist
    -- In overwrite mode the file is rewritten from scratch every time, so it holds the latest row only and carries no header
    procedure Write_Row (Filename : in String;
                         Header : in String;
                         Row : in String;
                         Overwrite : in Boolean) is
        Output : File_Type;
    begin
        if Overwrite then
            Create (Output, Out_File, Filename);
        else
            begin
                Open (Output, Append_File, Filename);
            exception
                when Name_Error =>
                    -- The file doesn't exist, so create it and start it with the header
                    Create (Output, Out_File, Filename);
                    Put_Line (Output, Header);
            end;
        end if;

        Put_Line (Output, Row);
        Close (Output);
    exception
        when others =>
            if not Reported.Contains (Filename) then
                Reported.Insert (Filename);
                Put_Line (Standard_Error,
                          "powerjoular: cannot write to " & Filename & ", the monitoring goes on without the file.");
            end if;

            begin
                if Is_Open (Output) then
                    Close (Output);
                end if;
            exception
                when others =>
                    null;
            end;
    end Write_Row;

    --------------------------------------------------

    procedure Save_System (Filename : in String;
                           Data : in Cycle;
                           Overwrite : in Boolean) is
    begin
        Write_Row
            (Filename => Filename,
             Header => "Timestamp,CPU Usage,Total Power,CPU Power,GPU Power",
             Row => Timestamp
                    & "," & Image (Data.CPU_Usage, Load_Decimals)
                    & "," & Image (Data.Total_Power, Power_Decimals)
                    & "," & Image (Data.CPU_Power, Power_Decimals)
                    & "," & Image (Data.GPU_Power, Power_Decimals),
             Overwrite => Overwrite);
    end Save_System;

    --------------------------------------------------

    procedure Save_Target (Filename : in String;
                           Data : in Cycle;
                           Overwrite : in Boolean) is
    begin
        Write_Row
            (Filename => Filename,
             Header => "Timestamp,CPU Usage,CPU Power",
             Row => Timestamp
                    & "," & Image (Data.Target_Usage, Load_Decimals)
                    & "," & Image (Data.Target_Power, Power_Decimals),
             Overwrite => Overwrite);
    end Save_Target;

end PowerJoular.CSV;
