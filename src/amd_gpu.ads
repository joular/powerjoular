--
--  Copyright (c) 2020-2026, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

package Amd_Gpu is

    -- Function get the power consumption of AMD GPUs (with rocm-smi or amd-smi)
    function Get_Amd_Gpu_Power return Long_Float;

    -- Function to check if we are running on a system with supported AMD GPUs
    function Check_Amd_Supported_System return Boolean;

end Amd_Gpu;
