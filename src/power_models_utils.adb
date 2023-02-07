--
--  Copyright (c) 2020-2022, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with GNAT.Expect; use GNAT.Expect;

package body Power_Models_Utils is
    
    function Read_Power_Models_File return Unbounded_String is
        F_Name : File_Type; -- File handle
        File_Name : constant String := "/etc/powerjoular/powerjoular_models.json"; -- File to read
        Data_From_File : Unbounded_String; -- Variable to store lines of the read file
    begin
        Open (F_Name, In_File, File_Name);
        while not End_Of_File (F_Name) loop
            Append (Data_From_File, String'(Get_Line (F_Name)));
        end loop;
        Close (F_Name);
        return Data_From_File;
    exception
        when others =>
            return To_Unbounded_String ("");
    end;
    
    procedure Update_Power_Models_File is
        -- Command to download file from URL using curl
        Command    : String          := "curl -o /etc/powerjoular/powerjoular_models.json https://raw.githubusercontent.com/joular/powerjoular/main/powermodels/powerjoular_models.json";
        Args       : Argument_List_Access;
        Status     : aliased Integer;
    begin
        Args := Argument_String_To_List (Command);
        declare
            Response : String :=
              Get_Command_Output
                (Command   => Args (Args'First).all,
                 Arguments => Args (Args'First + 1 .. Args'Last),
                 Input     => "",
                 Status    => Status'Access);
        begin
            Free (Args);
        end;
    exception
        when others =>
            Put_Line ("Error accessing URL or writing to file");
            OS_Exit (0);
    end;
    
end Power_Models_Utils;
