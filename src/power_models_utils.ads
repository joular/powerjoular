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

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Power_Models_Utils is
    
    -- Function to read PowerJoular's power models file and return its content as a string
    function Read_Power_Models_File return Unbounded_String;
    
    -- Function to update PowerJoular's power models file from the internet
    procedure Update_Power_Models_File;
    
end Power_Models_Utils;
