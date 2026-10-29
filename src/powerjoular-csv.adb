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

with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib;

with CPU_Load;

with PowerJoular.Formatting; use PowerJoular.Formatting;
with PowerJoular.Platform;
with PowerJoular.Terminal;

package body PowerJoular.CSV is

    use type Ada.Directories.File_Kind;
    use type Ada.Directories.File_Size;
    use type GNAT.OS_Lib.File_Descriptor;

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

    -- power.csv gives power-144.csv for the process 144, power-firefox.csv for Firefox
    function Target_File_Name (Base : in String; Target : in String) return String is
        Stem : constant String :=
            (if Base'Length > 4 and then To_Lower (Base (Base'Last - 3 .. Base'Last)) = ".csv"
             then Base (Base'First .. Base'Last - 4)
             else Base);
    begin
        return Stem & "-" & Target & ".csv";
    end Target_File_Name;

    --------------------------------------------------

    -- Folder separators, the other characters that Windows refuses in a name and control characters are replaced
    -- So the file lands in the folder given, with the same name on every OS
    function File_Name_Part (Name : in String) return String is
        Result : String := Name;
    begin
        for C of Result loop
            if C in '/' | '\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' or else C < ' ' then
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
                    To_Unbounded_String (Target_File_Name (Base, Trim (CPU_Load.Process_ID'Image (Config.PID), Left)));

            when One_Application =>
                Target_File.Name :=
                    To_Unbounded_String (Target_File_Name (Base, File_Name_Part (To_String (Config.App))));
        end case;
    end Start;

    --------------------------------------------------

    procedure Report (File : in out Output_File; Message : in String) is
    begin
        if not File.Reported then
            File.Reported := True;
            Terminal.Report (Message & ", the monitoring goes on without the file.");
        end if;
    end Report;

    --------------------------------------------------

    -- Write Line and a line end, True if all of it was written
    function Write_Line (Output : in GNAT.OS_Lib.File_Descriptor; Line : in String) return Boolean is
        Text : constant String := Line & ASCII.LF;
    begin
        return GNAT.OS_Lib.Write (Output, Text'Address, Text'Length) = Text'Length;
    end Write_Line;

    --------------------------------------------------

    -- Add Row to the file, and start a new or empty file with Header
    -- In overwrite mode, the file is replaced by Row only, written whole beside it first so a reader never finds it empty
    procedure Write_Row (File : in out Output_File; Header : in String; Row : in String) is
        Name : constant String := To_String (File.Name);
        Temporary : constant String := Name & ".tmp";
        Appending : Boolean := False;
        Output : GNAT.OS_Lib.File_Descriptor;
        Written : Boolean := False;
        Ignored : Boolean;
    begin
        -- PowerJoular often runs as root, so the file is never opened through a symbolic link (see Platform.Open_Output) and only a plain file is replaced: a device such as /dev/null would become one otherwise
        if Overwrite and then Ada.Directories.Exists (Name)
           and then Ada.Directories.Kind (Name) /= Ada.Directories.Ordinary_File
        then
            Output := GNAT.OS_Lib.Invalid_FD;
        elsif Overwrite then
            Output := Platform.Open_Output (Temporary, Append => False);
        else
            Appending := Ada.Directories.Exists (Name) and then Ada.Directories.Size (Name) > 0;
            Output := Platform.Open_Output (Name, Append => Appending);
        end if;

        if Output /= GNAT.OS_Lib.Invalid_FD then
            Written := Write_Line (Output, (if Overwrite or else Appending then Row else Header & ASCII.LF & Row));
            GNAT.OS_Lib.Close (Output);
        end if;

        -- The rename replaces whatever is at Name, a link included, without writing through it
        if Written and then Overwrite then
            Written := Platform.Replace_File (Temporary, Name);
        end if;

        if not Written then
            -- Left beside the file, the temporary would be rewritten every second
            if Overwrite then
                GNAT.OS_Lib.Delete_File (Temporary, Ignored);
            end if;

            Report (File, "cannot write to " & Name);
        end if;
    exception
        when others =>
            Report (File, "cannot write to " & Name);
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

    --------------------------------------------------

    function Target_Name return String is (if Has_Target_File then To_String (Target_File.Name) else "");

end PowerJoular.CSV;
