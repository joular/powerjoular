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

with Ada.Directories;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;

with CPU_Load;

with PowerJoular.Formatting; use PowerJoular.Formatting;
with PowerJoular.Platform;
with PowerJoular.Terminal;

package body PowerJoular.CSV is

    use type Ada.Directories.File_Size;

    Decimals : constant := 4;

    System_Header : constant String := "Timestamp,CPU Usage,Total Power,CPU Power,GPU Power";
    Target_Header : constant String := "Timestamp,CPU Usage,CPU Power";

    type Output_File is
        record
            Name : Unbounded_String;
            Reported : Boolean := False; -- A failure to write was already reported
        end record;

    System_File : Output_File;
    Target_File : Output_File;
    Has_Target_File : Boolean := False;

    -- Keep only the latest row
    Overwrite : Boolean := False;

    --------------------------------------------------

    -- Folder separators and ':' (NTFS streams) are replaced, so the file lands in the folder given
    function File_Name_Part (Name : in String) return String is
        Result : String := Name;
    begin
        for C of Result loop
            if C = '/' or else C = '\' or else C = ':' then
                C := '_';
            end if;
        end loop;

        return Result;
    end File_Name_Part;

    --------------------------------------------------

    procedure Start (Config : in Options.Settings) is
        Base : constant String := To_String (Config.CSV_File);
    begin
        Overwrite := Config.Overwrite;
        System_File := (Name => Config.CSV_File, Reported => False);
        Has_Target_File := Config.Target /= Whole_System;

        case Config.Target is
            when Whole_System =>
                null;

            when One_Process =>
                Target_File.Name :=
                    To_Unbounded_String (Base & "-" & Trim (CPU_Load.Process_ID'Image (Config.PID), Left) & ".csv");

            when One_Application =>
                Target_File.Name :=
                    To_Unbounded_String (Base & "-" & File_Name_Part (To_String (Config.App)) & ".csv");
        end case;
    end Start;

    --------------------------------------------------

    procedure Report (File : in out Output_File; Message : in String) is
    begin
        if not File.Reported then
            File.Reported := True;
            Terminal.Close_Line;
            Put_Line (Standard_Error, "powerjoular: " & Message & ", the monitoring goes on without the file.");
        end if;
    end Report;

    --------------------------------------------------

    -- Add Row to the file, and start a new or empty file with Header
    -- In overwrite mode, the file is rewritten with Row only
    procedure Write_Row (File : in out Output_File; Header : in String; Row : in String) is
        Name : constant String := To_String (File.Name);
        Output : File_Type;
    begin
        -- PowerJoular often runs as root, so refuse a link that may point at a system file (not race free, see the README)
        if Platform.Is_Symbolic_Link (Name) then
            Report (File, Name & " is a symbolic link and is not written to");
            return;
        end if;

        if Overwrite then
            Create (Output, Out_File, Name);
        elsif Ada.Directories.Exists (Name) and then Ada.Directories.Size (Name) > 0 then
            Open (Output, Append_File, Name);
        else
            Create (Output, Out_File, Name);
            Put_Line (Output, Header);
        end if;

        Put_Line (Output, Row);
        Close (Output);
    exception
        when others =>
            Report (File, "cannot write to " & Name);

            if Is_Open (Output) then
                begin
                    Close (Output);
                exception
                    when others =>
                        null;
                end;
            end if;
    end Write_Row;

    --------------------------------------------------

    procedure Write (Data : in Cycle) is
        Time : constant String := Trim (Long_Long_Integer'Image (Data.Time), Left);
    begin
        Write_Row (System_File,
                   Header => System_Header,
                   Row => Time
                          & "," & Image (Data.CPU_Usage, Decimals)
                          & "," & Image (Data.Total_Power, Decimals)
                          & "," & Image (Data.CPU_Power, Decimals)
                          & "," & Image (Data.GPU_Power, Decimals));

        if Has_Target_File then
            Write_Row (Target_File,
                       Header => Target_Header,
                       Row => Time
                              & "," & Image (Data.Target_Usage, Decimals)
                              & "," & Image (Data.Target_Power, Decimals));
        end if;
    end Write;

end PowerJoular.CSV;
