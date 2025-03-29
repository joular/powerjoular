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

package Nvidia_SMI is

    -- Function to return the current Nvidia board power consumption using nvidia-smi
    function Get_Nvidia_SMI_Power return Long_Float;
    
    -- Function to check if we have a supported Nvidia card and drivers and nvidia-smi tool
    function Check_Nvidia_Supported_System return Boolean;
    
end Nvidia_SMI;
