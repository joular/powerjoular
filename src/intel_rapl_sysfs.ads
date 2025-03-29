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

package Intel_RAPL_sysfs is

   -- Type to store Intel RAPL energy data
    type Intel_RAPL_Data is
        record
            -- Data to store energy measures
            psys : Long_Float; -- Energy for psys (whole SOC)
            pkg : Long_Float; -- Energy for all packages
            dram : Long_Float; -- Energy for all dram
           
            -- Total energy is equal to psys if supoprted, or to pkg + dram
            total_energy : Long_Float := 0.0; -- Total energy
            
            -- Data to store if packages are supported
            psys_supported : Boolean := False; -- if system supports psys
            pkg_supported : Boolean := False; -- if system supports pkg 0
            dram_supported : Boolean := False; -- if system support dram 0

            -- Data to store max energy ranges
            pkg_max_energy_range : Long_Float := 0.0; -- pkg max_energy_range_uj
            psys_max_energy_range : Long_Float := 0.0; -- psys max_energy_range_uj
            dram_max_energy_range : Long_Float := 0.0; -- dram max_energy_range_uj
        end record;
    
    -- Calculate total energy consumption from Linux powercap sysfs
    procedure Calculate_Energy (RAPL_Data : in out Intel_RAPL_Data);

    -- Check if package is supported (psys, package-0, or dram)
    -- That is: content of file /sys/devices/virtual/powercap/intel-rapl/intel-rapl:1/name is "psys"
    -- That is: content of file /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/name is "package-0"
    -- That is: content of file /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:2/name is "package-0"
    -- So far, only package 0 is supported (and dram in package 0)
    procedure Check_Supported_Packages (RAPL_Data : in out Intel_RAPL_Data; Package_Name : in String);

    procedure Get_Max_Energy_Range (RAPL_Data : in out Intel_RAPL_Data; Package_Name : in String);
end Intel_RAPL_sysfs;
