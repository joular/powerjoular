--
--  Copyright (c) 2020-2025, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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

package Virtual_Machine is

    -- Read virtual machine power data from the shared file and returns the power consumption of the entire VM
    function Read_VM_Power(File_Name : Unbounded_String; Power_Format : Unbounded_String) return Long_Float;

end Virtual_Machine;
