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

package OS_Utils is

    -- Function to check if we are running on an system using an Intel processor
    function Check_Intel_Supported_System (Platform_Name : in String) return Boolean;

    -- Function to check if we are running on a supported Raspberry Pi device
    function Check_Raspberry_Pi_Supported_System (Platform_Name : in String) return Boolean;

    -- Get the name of the current platform (intel, amd, raspberry) using a codename per supported platform
    -- For AMD, return only the platform name if the CPU is Ryzen as older ones are not supported
    -- Return empty string if platform is not supported
    function Get_Platform_Name return String;

    -- Get the name of the operating system from environmental variable
    -- Return empty string is OS can't be detected
    function Get_OS_Name return String;

end OS_Utils;
