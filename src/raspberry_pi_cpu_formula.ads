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

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Raspberry_Pi_CPU_Formula is

    -- Function to calculate CPU power consumption based on CPU utilization
    function Calculate_CPU_Power (CPU_Utilization : Long_Float; Platform_Name : String; Algorithm_Name : String) return Long_Float;

end Raspberry_Pi_CPU_Formula;
