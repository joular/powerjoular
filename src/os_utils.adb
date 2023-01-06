--
--  Copyright (c) 2020-2021, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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
        return Platform_Name in "rbp4001.0-64" | "rbp4b1.2" | "rbp4b1.2-64" | "rbp4b1.1" | "rbp4b1.1-64" | "rbp3b+1.3" | "rbp3b1.2" | "rbp2b1.1" | "rbp1b+1.2" | "rbp1b2" | "rbpzw1.1" | "asustbs";
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

            Index_Search := Index (To_String (Line_String), "Raspberry Pi 400 Rev 1.0");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4001.0-64";
                end if;
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi 4 Model B Rev 1.2");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4b1.2-64";
                else
                    return "rbp4b1.2";
                end if;
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi 4 Model B Rev 1.1");
            if (Index_Search > 0) then
                if (Architecture_Name = "aarch64") then
                    return "rbp4b1.1-64";
                else
                    return "rbp4b1.1";
                end if;
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi 3 Model B Plus Rev 1.3");
            if (Index_Search > 0) then
                return "rbp3b+1.3";
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi 3 Model B Rev 1.2");
            if (Index_Search > 0) then
                return "rbp3b1.2";
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi 2 Model B Rev 1.1");
            if (Index_Search > 0) then
                return "rbp2b1.1";
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi Model B Plus Rev 1.2");
            if (Index_Search > 0) then
                return "rbp1b+1.2";
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi Model B Rev 2");
            if (Index_Search > 0) then
                return "rbp1b2";
            end if;

            Index_Search := Index (To_String (Line_String), "Raspberry Pi Zero W Rev 1.1");
            if (Index_Search > 0) then
                return "rbpzw1.1";
            end if;

            Index_Search := Index (To_String (Line_String), "ASUS Tinker Board (S)");
            if (Index_Search > 0) then
                return "asustbs";
            end if;
        end loop;

        Close (F_Name);

        return "";
    exception
        when others =>
            Put_Line ("Wrong platform or error reading file: " & File_Name);
            OS_Exit (0);
    end;

    function Get_Platform_Name return String is
        F_Name : File_Type; -- File handle
        File_Name : constant String := "/proc/cpuinfo"; -- File to read
        Index_Search : Integer; -- Index of platform name in the searched string
        Line_String : Unbounded_String; -- Variable to store each line of the read file
        AMD_vendor : Unbounded_String; -- AMD vendor name
    begin
        Open (F_Name, In_File, File_Name);
        -- Loop through file to check if it's one of the supported ones and get its name
        while not End_Of_File (F_Name) loop
            Line_String := To_Unbounded_String (Get_Line (F_Name));
            
            Index_Search := Index (To_String (Line_String), "GenuineIntel");
            if (Index_Search > 0) then
                return "intel";
            end if;
            
            Index_Search := Index (To_String (Line_String), "AuthenticAMD");
            if (Index_Search > 0) then
                AMD_vendor := To_Unbounded_String ("amd");
            end if;

        end loop;
        
        Close (F_Name);
        
        if (AMD_vendor = "amd") then
            Open (F_Name, In_File, File_Name);
            
            while not End_Of_File (F_Name) loop
                Line_String := To_Unbounded_String (Get_Line (F_Name));
            
                Index_Search := Index (To_String (Line_String), "Ryzen");
                if (Index_Search > 0) then
                    return "amd";
                end if;

            end loop;
            
            Close (F_Name);
        end if;

        return Get_Platform_Name_Raspberry;
    exception
        when others =>
            -- Put_Line ("Error reading file: " & File_Name);
            -- Put_Line (Get_OS_Name);
            -- OS_Exit (0);
            return "";
    end;
    
    function Get_OS_Name return String is
    begin
        if (Ada.Environment_Variables.Exists ("OS")) then
            return Ada.Environment_Variables.Value ("OS");
        else
            return "";
        end if;
    end;

end OS_Utils;
