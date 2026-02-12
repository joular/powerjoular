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
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.Expect; use GNAT.Expect;
with Ada.Environment_Variables; use Ada.Environment_Variables;

package body OS_Utils is
       
    function Check_Intel_Supported_System (Platform_Name : in String) return Boolean is
    begin
        return Platform_Name in "intel" | "amd";
    end;

    -- Check if platform supports Raspberry Pi
    function Check_Raspberry_Pi_Supported_System (Platform_Name : in String) return Boolean is
    begin
        return Platform_Name in "rbp5b1.0-64" | "rbp4001.0-64" | "rbp4b1.2" | "rbp4b1.2-64" | "rbp4b1.1" | "rbp4b1.1-64" | "rbp3b+1.3" | "rbp3b1.2" | "rbp2b1.1" | "rbp1b+1.2" | "rbp1b2" | "rbpzw1.1" | "asustbs";
    end;

    -- Get architecture name (uname -m)
    function Get_Architecture_Name return String is
        Command    : String          := "uname -m";
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
            return Response;
        end;
    exception
        when others =>
            return "";
    end;

    -- Get the name of the current platform (Raspberry) using a codename per supported platform
    -- Return empty string if platform is not supported
    function Get_Platform_Name_Raspberry return String is
        F_Name : File_Type; -- File handle
        File_Name : constant String := "/proc/device-tree/model"; -- File to read
        Index_Search : Integer; -- Index of platform name in the searched string
        Line_String : Unbounded_String; -- Variable to store each line of the read file
        Architecture_Name : String := Get_Architecture_Name; -- Architecture name (32/84 bits, arm/x86)
    begin
        Open (F_Name, In_File, File_Name);
        -- Loop through file to check if it's one of the supported ones and get its name
        while not End_Of_File (F_Name) loop
            Line_String := To_Unbounded_String (Get_Line (F_Name));

            -- Specific model used to train the energy models
            
            -- Raspberry Pi 5B 1.0
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 5 Model B Rev 1.0");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp5b1.0-64";
                end if;
            end if;

            -- Raspberry Pi 400 1.0
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 400 Rev 1.0");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4001.0-64";
                end if;
            end if;

            -- Raspberry Pi 4B 1.2
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 4 Model B Rev 1.2");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4b1.2-64";
                else
                    return "rbp4b1.2";
                end if;
            end if;

            -- Raspberry Pi 4B 1.1
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 4 Model B Rev 1.1");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4b1.1-64";
                else
                    return "rbp4b1.1";
                end if;
            end if;

            -- Raspberry Pi 3B+ 1.3
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 3 Model B Plus Rev 1.3");
            if (Index_Search > 0) then
                return "rbp3b+1.3";
            end if;

            -- Raspberry Pi 3B 1.2
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 3 Model B Rev 1.2");
            if (Index_Search > 0) then
                return "rbp3b1.2";
            end if;

            -- Raspberry Pi 2B 1.1
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 2 Model B Rev 1.1");
            if (Index_Search > 0) then
                return "rbp2b1.1";
            end if;

            -- Raspberry Pi B+ 1.2
            Index_Search := Index (To_String (Line_String), "Raspberry Pi Model B Plus Rev 1.2");
            if (Index_Search > 0) then
                return "rbp1b+1.2";
            end if;

            -- Raspberry Pi B 2
            Index_Search := Index (To_String (Line_String), "Raspberry Pi Model B Rev 2");
            if (Index_Search > 0) then
                return "rbp1b2";
            end if;

            -- Raspberry Pi Zero W 1.1
            Index_Search := Index (To_String (Line_String), "Raspberry Pi Zero W Rev 1.1");
            if (Index_Search > 0) then
                return "rbpzw1.1";
            end if;

            -- Asus Tinker Board (S)
            Index_Search := Index (To_String (Line_String), "ASUS Tinker Board (S)");
            if (Index_Search > 0) then
                return "asustbs";
            end if;

            -- Supporting other revisions where specific energy models were not generated
            -- In this case, we use the model of the same RPi model but different revision
            
            -- Raspberry Pi 5B
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 5 Model B");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp5b1.0-64";
                end if;
            end if;

            -- Raspberry Pi 400
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 400");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4001.0-64";
                end if;
            end if;

            -- Raspberry Pi 4B
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 4 Model B");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4b1.2-64";
                else
                    return "rbp4b1.2";
                end if;
            end if;

            -- Raspberry Pi 3B+
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 3 Model B Plus");
            if (Index_Search > 0) then
                return "rbp3b+1.3";
            end if;

            -- Raspberry Pi 3B
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 3 Model B");
            if (Index_Search > 0) then
                return "rbp3b1.2";
            end if;

            -- Raspberry Pi 2B
            Index_Search := Index (To_String (Line_String), "Raspberry Pi 2 Model B");
            if (Index_Search > 0) then
                return "rbp2b1.1";
            end if;

            -- Raspberry Pi B+
            Index_Search := Index (To_String (Line_String), "Raspberry Pi Model B Plus");
            if (Index_Search > 0) then
                return "rbp1b+1.2";
            end if;

            -- Raspberry Pi B
            Index_Search := Index (To_String (Line_String), "Raspberry Pi Model B");
            if (Index_Search > 0) then
                return "rbp1b2";
            end if;

            -- Raspberry Pi Zero W
            Index_Search := Index (To_String (Line_String), "Raspberry Pi Zero W");
            if (Index_Search > 0) then
                return "rbpzw1.1";
            end if;

            -- Asus Tinker Board
            Index_Search := Index (To_String (Line_String), "ASUS Tinker Board");
            if (Index_Search > 0) then
                return "asustbs";
            end if;
        end loop;

        Close (F_Name);

        return "";
    exception
        when others =>
            Put_Line (Standard_Error, "Wrong platform or error reading file: " & File_Name);
            OS_Exit (0);
    end;

    function Get_Platform_Name return String is
        F_Name : File_Type; -- File handle
        File_Name : constant String := "/proc/cpuinfo"; -- File to read
        Index_Search : Integer; -- Index of platform name in the searched string
        Line_String : Unbounded_String; -- Variable to store each line of the read file
        Is_AMD : Boolean := False; -- AMD vendor flag
    begin
        Open (F_Name, In_File, File_Name);
        -- Loop through file to check if it's one of the supported ones and get its name
        while not End_Of_File (F_Name) loop
            Line_String := To_Unbounded_String (Get_Line (F_Name));
            
            Index_Search := Index (To_String (Line_String), "GenuineIntel");
            if (Index_Search > 0) then
                Close (F_Name);
                return "intel";
            end if;
            
            Index_Search := Index (To_String (Line_String), "AuthenticAMD");
            if (Index_Search > 0) then
                Is_AMD := True;
            end if;

            if Is_AMD then
                Index_Search := Index (To_String (Line_String), "Ryzen");
                if (Index_Search > 0) then
                    Close (F_Name);
                    return "amd";
                end if;

                Index_Search := Index (To_String (Line_String), "EPYC");
                if (Index_Search > 0) then
                    Close (F_Name);
                    return "amd";
                end if;
            end if;
        end loop;
        
        Close (F_Name);

        return Get_Platform_Name_Raspberry;
    exception
        when others =>
            return "";
    end;
    
    function Get_OS_Name return String is
        Command    : String          := "uname -s";
        Args       : Argument_List_Access;
        Status     : aliased Integer;
    begin
        if (Ada.Environment_Variables.Exists ("OS")) then
            return Ada.Environment_Variables.Value ("OS");
        else
            -- Fallback to uname -s for Linux/Unix
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
                if Response'Length > 0 and then Response (Response'Last) = ASCII.LF then
                    return Response (Response'First .. Response'Last - 1);
                else
                    return Response;
                end if;
            end;
        end if;
    exception
        when others =>
            return "Unknown";
    end;

end OS_Utils;
