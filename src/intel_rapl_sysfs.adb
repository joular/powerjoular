--
--  Copyright (c) 2020-2024, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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

package body Intel_RAPL_sysfs is

    procedure Calculate_Energy (RAPL_Data : in out Intel_RAPL_Data) is
        F_Name : File_Type; -- File handle
        Folder_Name : constant String := "/sys/class/powercap/intel-rapl/"; -- Folder prefix for file to read
    begin
        if RAPL_Data.psys_supported then
            -- Read energy_uj which is in micro joules
            Open (F_Name, In_File, Folder_Name & "intel-rapl:1/energy_uj");
            -- Store energy value divided by 1000000 to get it in joules
            RAPL_Data.psys := Long_Float'Value (Get_Line (F_Name)) / 1000000.0;
            Close (F_Name);
            RAPL_Data.total_energy := RAPL_Data.psys;
        elsif RAPL_Data.pkg_supported then
            -- Read energy_uj which is in micro joules
            Open (F_Name, In_File, Folder_Name & "intel-rapl:0/energy_uj");
            -- Store energy value divided by 1000000 to get it in joules
            RAPL_Data.pkg := Long_Float'Value (Get_Line (F_Name)) / 1000000.0;
            Close (F_Name);
            RAPL_Data.total_energy := RAPL_Data.pkg;

            -- For pkg, also check dram because total energy = pkg + dram
            if RAPL_Data.dram_supported then
                begin
                    -- Read energy_uj which is in micro joules
                    Open (F_Name, In_File, Folder_Name & "intel-rapl:0/intel-rapl:0:2/energy_uj");
                    -- Store energy value divided by 1000000 to get it in joules
                    RAPL_Data.dram := Long_Float'Value (Get_Line (F_Name)) / 1000000.0;
                    Close (F_Name);
                    RAPL_Data.total_energy := RAPL_Data.pkg + RAPL_Data.dram;
                exception
                    when others =>
                        -- Don't exit because we can continue without dram
                        null;
                end;
            end if;
        else
            return;
        end if;
    exception
        when others =>
            RAPL_Data.total_energy := 0.0;
            Put_Line ("Error reading file. Did you run with root privileges?");
            OS_Exit (0);
    end;

    procedure Check_Supported_Packages (RAPL_Data : in out Intel_RAPL_Data; Package_Name : in String) is
        F_Name : File_Type; -- File handle
        Folder_Name : constant String := "/sys/class/powercap/intel-rapl/"; -- Folder prefix for file to read
    begin
        if (Package_Name = "psys") then
            Open (F_Name, In_File, Folder_Name & "intel-rapl:1/name");
        elsif (Package_Name = "pkg") then
            Open (F_Name, In_File, Folder_Name & "intel-rapl:0/name");
        elsif (Package_Name = "dram") then
            Open (F_Name, In_File, Folder_Name & "intel-rapl:0/intel-rapl:0:2/name");
        else
            return;
        end if;

        declare
            Name_Intel : String := Get_Line (F_Name);
        begin
            if (Name_Intel = "psys") then
                RAPL_Data.psys_supported := True;
            elsif (Name_Intel = "package-0") then
                RAPL_Data.pkg_supported := True;
            elsif (Name_Intel = "dram") then
                RAPL_Data.dram_supported := True;
            else
                return;
            end if;
        end;
        Close (F_Name);
    exception
        when others =>
            return; -- When failing to read powercap file, fail without printing messages on terminal
            --Put_Line ("Error reading file " & Package_Name & " for Intel RAPL.");
    end;

    procedure Get_Max_Energy_Range (RAPL_Data : in out Intel_RAPL_Data; Package_Name : in String) is
        F_Name : File_Type; -- File handle
        Folder_Name : constant String := "/sys/class/powercap/intel-rapl/"; -- Folder prefix for file to read
    begin
        if (Package_Name = "psys") then
            Open (F_Name, In_File, Folder_Name & "intel-rapl:1/max_energy_range_uj");
            RAPL_Data.psys_max_energy_range := Long_Float'Value (Get_Line (F_Name)) / 1000000.0;
            Close (F_Name);
        elsif (Package_Name = "pkg") then
            Open (F_Name, In_File, Folder_Name & "intel-rapl:0/max_energy_range_uj");
            RAPL_Data.pkg_max_energy_range := Long_Float'Value (Get_Line (F_Name)) / 1000000.0;
            Close (F_Name);
        elsif (Package_Name = "dram") then
            Open (F_Name, In_File, Folder_Name & "intel-rapl:0/intel-rapl:0:2/max_energy_range_uj");
            RAPL_Data.dram_max_energy_range := Long_Float'Value (Get_Line (F_Name)) / 1000000.0;
            Close (F_Name);
        end if;
    exception
        when others =>
            return;
    end;

end Intel_RAPL_sysfs;
