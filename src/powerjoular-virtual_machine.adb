--
--  Copyright (c) 2020-2026, Adel Noureddine.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Axel Terrier
--  Contributors : Adel Noureddine
--

with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Directories;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Maps; use Ada.Strings.Maps;
with Ada.Text_IO; use Ada.Text_IO;

with PowerJoular.Terminal;

package body PowerJoular.Virtual_Machine is

    use type Ada.Directories.File_Kind;

    -- The host may run another OS, with other line endings
    Blanks : constant Character_Set := To_Set (" " & CR & LF & HT);

    -- A power value never needs that many characters, a longer line is not one
    Max_Line_Length : constant := 256;

    Last_Power : Long_Float := 0.0;
    Ever_Read : Boolean := False;

    -- The host may be rewriting the file, so one failed read is not reported, and a lasting failure only once
    Failed_Last : Boolean := False;
    Reported_Failure : Boolean := False;

    --------------------------------------------------

    function Format_Of (Name : in String; Format : out File_Format) return Boolean is
    begin
        Format := (if Name = "powerjoular" then PowerJoular_CSV else Watts);
        return Name = "powerjoular" or else Name = "watts";
    end Format_Of;

    --------------------------------------------------

    -- The comma separated field at Position (from 1), or an empty string if the line has fewer fields
    function Field (Line : in String; Position : in Positive) return String is
        First : Positive := Line'First;
        Count : Positive := 1;
    begin
        for I in Line'Range loop
            if Line (I) = ',' then
                if Count = Position then
                    return Line (First .. I - 1);
                end if;

                Count := Count + 1;
                First := I + 1;
            end if;
        end loop;

        return (if Count = Position then Line (First .. Line'Last) else "");
    end Field;

    --------------------------------------------------

    function Read (File_Name : in String; Format : in File_Format; Power : out Long_Float) return Boolean is
        Input : File_Type;
        Line : String (1 .. Max_Line_Length);
        Last : Natural;
    begin
        Power := 0.0;

        -- A named pipe or a device would block Open until someone writes to it
        if Ada.Directories.Kind (File_Name) /= Ada.Directories.Ordinary_File then
            return False;
        end if;

        -- The host writes the latest power on the first line
        Open (Input, In_File, File_Name);
        Get_Line (Input, Line, Last);
        Close (Input);

        if Last = Line'Last then
            return False;
        end if;

        declare
            Text : constant String :=
                (case Format is
                    when Watts => Line (1 .. Last),
                    when PowerJoular_CSV => Field (Line (1 .. Last), 3));
        begin
            Power := Long_Float'Value (Trim (Text, Blanks, Blanks));
        end;

        -- PowerJoular writes -1 for a process it could not read
        return Power >= 0.0;
    exception
        when others =>
            if Is_Open (Input) then
                Close (Input);
            end if;

            return False;
    end Read;

    --------------------------------------------------

    function Power (File_Name : in String; Format : in File_Format) return Long_Float is
        Value : Long_Float;
    begin
        if Read (File_Name, Format, Value) then
            Last_Power := Value;
            Ever_Read := True;
            Failed_Last := False;
        elsif not Failed_Last then
            Failed_Last := True;
        elsif not Reported_Failure then
            Reported_Failure := True;
            Terminal.Close_Line;
            Put_Line (Standard_Error,
                      "powerjoular: cannot read the power of this machine from " & File_Name
                      & (if Ever_Read then ", keeping the last value read."
                         else ", reporting no power until it can be read."));
        end if;

        return Last_Power;
    end Power;

end PowerJoular.Virtual_Machine;
