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
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Maps; use Ada.Strings.Maps;
with Ada.Text_IO; use Ada.Text_IO;

package body PowerJoular.Virtual_Machine is

    -- The two formats the shared file can be in
    PowerJoular_Format : constant String := "powerjoular";
    Watts_Format : constant String := "watts";

    -- Spaces and end of line characters that surround the value, the file being written by a tool on another machine which may be another OS with different line endings
    Blanks : constant Character_Set := To_Set (" " & CR & LF & HT);

    -- The power of the previous cycle, kept so a file that can't be read for a moment doesn't read as no power at all
    Last_Known : Long_Float := 0.0;

    -- Set once the file could not be read
    Reported_A_Failure : Boolean := False;

    -- Whether a power value was ever read out of the file, so a file that never gave one is not reported as keeping a last value it never had
    Ever_Read : Boolean := False;

    --------------------------------------------------

    function Is_Known_Format (Name : in String) return Boolean is
        (Name in PowerJoular_Format | Watts_Format);

    --------------------------------------------------

    -- The comma separated field of the given position, counting from one
    -- Returns an empty string when the line doesn't have that many fields
    function Field (Line : in String; Position : in Positive) return String is
        First : Natural := Line'First;
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

        -- The last field of the line has no comma after it
        if Count = Position then
            return Line (First .. Line'Last);
        end if;

        return "";
    end Field;

    --------------------------------------------------

    -- Read the power out of the file, and say whether it could be read at all
    -- Both the check made before the monitoring starts and every cycle of the monitoring itself go through here
    procedure Read_Value (File_Name : in String;
                          Format : in String;
                          Value : out Long_Float;
                          Read_It : out Boolean) is
        Input : File_Type;
    begin
        Value := 0.0;
        Read_It := False;

        Open (Input, In_File, File_Name);

        declare
            -- The host writes the latest power on the first line
            Line : constant String := Trim (Get_Line (Input), Blanks, Blanks);

            -- The power on its own in the watts format, the third column in the PowerJoular one
            Text : constant String :=
                (if Format = Watts_Format then Line else Trim (Field (Line, 3), Blanks, Blanks));
        begin
            Close (Input);
            Value := Long_Float'Value (Text);
            Read_It := True;
        end;
    exception
        when others =>
            Read_It := False;

            begin
                if Is_Open (Input) then
                    Close (Input);
                end if;
            exception
                when others =>
                    null;
            end;
    end Read_Value;

    --------------------------------------------------

    function Can_Read (File_Name : in String; Format : in String) return Boolean is
        Value : Long_Float;
        Read_It : Boolean;
    begin
        Read_Value (File_Name, Format, Value, Read_It);

        -- What was read here is kept, so the first cycle already has a value even if the file happens to be halfway through being rewritten by the host at that moment
        if Read_It then
            Last_Known := Value;
            Ever_Read := True;
        end if;

        return Read_It;
    end Can_Read;

    --------------------------------------------------

    function Power (File_Name : in String; Format : in String) return Long_Float is
        Value : Long_Float;
        Read_It : Boolean;
    begin
        Read_Value (File_Name, Format, Value, Read_It);

        if Read_It then
            Last_Known := Value;
            Ever_Read := True;
            return Last_Known;
        end if;

        -- The file may be halfway through being rewritten by the host, in this case the next cycle reads it fine, so for now we can report the last known reading
        if not Reported_A_Failure then
            Reported_A_Failure := True;

            if Ever_Read then
                Put_Line (Standard_Error,
                          "powerjoular: cannot read the power of this machine from " & File_Name & ", keeping the last value read.");
            else
                Put_Line (Standard_Error,
                          "powerjoular: cannot read the power of this machine from " & File_Name & ", reporting no power until it can be read.");
            end if;
        end if;

        return Last_Known;
    end Power;

end PowerJoular.Virtual_Machine;
