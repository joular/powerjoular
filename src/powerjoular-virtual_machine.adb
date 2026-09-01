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

    function Power (File_Name : in String; Format : in String) return Long_Float is
        Input : File_Type;
    begin
        Open (Input, In_File, File_Name);

        declare
            -- The host writes the latest power on the first line
            Line : constant String := Trim (Get_Line (Input), Blanks, Blanks);

            -- The power on its own in the watts format, the third column in the PowerJoular one
            Value : constant String :=
                (if Format = Watts_Format then Line else Trim (Field (Line, 3), Blanks, Blanks));
        begin
            Close (Input);
            Last_Known := Long_Float'Value (Value);
        end;

        return Last_Known;
    exception
        when others =>
            -- The file may be halfway through being rewritten by the host, in this case the next cycle reads it fine, so for now we can report the last known reading
            if not Reported_A_Failure then
                Reported_A_Failure := True;
                Put_Line (Standard_Error,
                          "powerjoular: cannot read the power of this machine from " & File_Name & ", keeping the last value read.");
            end if;

            begin
                if Is_Open (Input) then
                    Close (Input);
                end if;
            exception
                when others =>
                    null;
            end;

            return Last_Known;
    end Power;

end PowerJoular.Virtual_Machine;
