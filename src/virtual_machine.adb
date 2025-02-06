--
--  Copyright (c) 2020-2024, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Axel Terrier
--  Contributors : Adel Noureddine
--

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Directories; use Ada.Directories;
with Ada.Text_IO; use Ada.Text_IO;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with GNAT.String_Split; use GNAT;
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Maps; use Ada.Strings.Maps;

package body Virtual_Machine is

    -- Read the exported data in PowerJoular format
    function Read_PowerJoular (File_Path : String) return Long_Float is
        F : File_Type; -- File handle
        Line  : Unbounded_String;
        Subs : String_Split.Slice_Set; -- Used to slice the read data from stat file
        Seps : constant String := ","; -- Seperator (space) for slicing string
        Power_Value : Long_Float;
    begin
        Open (F, In_File, File_Path);
        Line := To_Unbounded_String (Get_Line (F)); -- Read data. We only need the first line of the file
        Close (F);

        -- Ensure the line is not empty before processing
        if Line /= To_Unbounded_String ("") then
            -- Processes the first line obtained
            String_Split.Create (S          => Subs, -- Store sliced data in Subs
                                 From       => To_String (Line),
                                 Separators => Seps, -- Separator
                                 Mode       => String_Split.Multiple);

            -- Converts the value of the third column (power consumption of PID or app, so of VM) into a float
            Power_Value := Long_Float'Value (String_Split.Slice (Subs, 3));

            return Power_Value;
        else
            return 0.0; -- Return 0 is file is empty
        end if;
    exception
        when others =>
            Put_Line (Standard_Error, "The file cannot be found, check the path");
            OS_Exit (0);
    end Read_PowerJoular;

    function Remove_CR (Line : Unbounded_String) return Unbounded_String is
        S : String := To_String (Line);
    begin
        if S'Length > 0 and then S(S'Last) = ASCII.CR then
            S := S(S'First .. S'Last - 1); -- Remove last character
        end if;

        return To_Unbounded_String (S);
    end Remove_CR;

    function Read_Watts (File_Path : String) return Long_Float is
        F      : File_Type;
        Line   : Unbounded_String;
        Result : Long_Float := 0.0;
    begin
        Open (F, In_File, File_Path);
        Line := To_Unbounded_String (Get_Line (F)); -- Read data. We only need the first line of the file.
        Close (F);

        -- Trim trailing CR caracter for Windows line ending if still present
        Line := Remove_CR (Line);

        -- Attempted conversion
        begin
            Result := Long_Float'Value (To_String (Line));
        exception
            when E : others =>
                Put_Line (Standard_Error, "Failed to convert to long float: " & Exception_Message (E));
                OS_Exit (0);
        end;

        return Result;
    exception
        when E : others =>
            Put_Line (Standard_Error, "Error after reading line: " & Exception_Message (E));
            OS_Exit (0);
    end Read_Watts;

    function Read_VM_Power (File_Name : Unbounded_String; Power_Format : Unbounded_String) return Long_Float is
        VM_File_Name : String := To_String(File_Name);
        VM_Power_Format : String := To_String(Power_Format);
        Power : Long_Float;

        -- Customized exceptions
        Invalid_File_Name_Exception : exception;
        Invalid_Format_Exception : exception;
    begin
        -- Check if file name parameter exist
        if VM_File_Name = "" then
            raise Invalid_File_Name_Exception;
        end if;

        -- Check file existence
        if not Exists (VM_File_Name) then
            raise Invalid_File_Name_Exception;
        end if;

        -- Iteration on supported formats
        if VM_Power_Format = ("powerjoular") then
            Power := Read_PowerJoular (VM_File_Name);
        else
            if VM_Power_Format = ("watts") then
                Power := Read_Watts (VM_File_Name);
            else
                raise Invalid_Format_Exception; -- Format not supported
            end if;
        end if;

        return Power;

    exception
        when Invalid_File_Name_Exception =>
            Put_Line (Standard_Error, "Error: The file name is invalid..");
            OS_Exit (0);
        when Invalid_Format_Exception    =>
            Put_Line (Standard_Error, "Error: The specified power format is not supported.");
            OS_Exit (0);
    end Read_VM_Power;

end Virtual_Machine;
