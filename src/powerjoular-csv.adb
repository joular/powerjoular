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
with Interfaces.C; use Interfaces.C;
with System;

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

    -- Say something about a file once, and never again about that same file
    procedure Report_Once (Filename : in String; Message : in String) is
    begin
        if not Reported.Contains (Filename) then
            Reported.Insert (Filename);
            Put_Line (Standard_Error, Message);
        end if;
    end Report_Once;

    --------------------------------------------------

#if PJ_WINDOWS then

    -- A symbolic link and a junction are both reparse points as far as Windows is concerned
    FILE_ATTRIBUTE_REPARSE_POINT : constant unsigned := 16#0000_0400#;

    -- What GetFileAttributesA hands back when it could not look at the path, a path that is not there included
    INVALID_FILE_ATTRIBUTES : constant unsigned := 16#FFFF_FFFF#;

    function GetFileAttributesA (lpFileName : System.Address) return unsigned;
    pragma Import (Stdcall, GetFileAttributesA, "GetFileAttributesA");

    function Is_Symbolic_Link (Filename : in String) return Boolean is
        Name : aliased constant char_array := To_C (Filename);
        Attributes : constant unsigned := GetFileAttributesA (Name'Address);
    begin
        -- A path that is not there yet is not a link, and is the usual case the first time round
        if Attributes = INVALID_FILE_ATTRIBUTES then
            return False;
        end if;

        return (Attributes and FILE_ATTRIBUTE_REPARSE_POINT) /= 0;
    exception
        when others =>
            return False;
    end Is_Symbolic_Link;

#else

    -- readlink is what tells a symbolic link apart from what it points at, and unlike lstat it needs nothing known about the shape of a system structure: it only succeeds on a link, and fails on anything else, a path that is not there at all included
    function C_Readlink (Path : in char_array;
                         Buffer : in System.Address;
                         Size : in size_t) return long;
    pragma Import (C, C_Readlink, "readlink");

    function Is_Symbolic_Link (Filename : in String) return Boolean is
        Name : constant char_array := To_C (Filename);
        Scratch : char_array (1 .. 1) := (others => nul);
    begin
        return C_Readlink (Name, Scratch'Address, 1) >= 0;
    exception
        when others =>
            return False;
    end Is_Symbolic_Link;

#end if;

    --------------------------------------------------

    -- Add one row to the file, and create it if not exist
    -- In overwrite mode the file is rewritten from scratch every time, so it holds the latest row only and carries no header
    procedure Write_Row (Filename : in String;
                         Header : in String;
                         Row : in String;
                         Overwrite : in Boolean) is
        Output : File_Type;
    begin
        -- PowerJoular is usually run as root, and the power data often goes to a folder shared with others
        -- A symbolic link left in the place of the file would have us write through it into someone else's file, so the file is written only where the path itself says
        -- The ring buffer is guarded the same way, with O_NOFOLLOW
        if Is_Symbolic_Link (Filename) then
            Report_Once (Filename,
                         "powerjoular: " & Filename & " is a symbolic link and is not written to, the monitoring goes on without the file.");
            return;
        end if;

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
            Report_Once (Filename,
                         "powerjoular: cannot write to " & Filename & ", the monitoring goes on without the file.");

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
