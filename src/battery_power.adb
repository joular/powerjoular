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

package body Battery_Power is
    
    -- Get current_now from :/sys/class/power_supply, and convert to ampere
    function Get_Current_Now return Float is
        F : File_Type; -- File handle
        File_Name : constant String := "/sys/class/power_supply/battery/current_now"; -- Filename to read
        Current_Now : Float;
    begin
        Open (F, In_File, File_Name);
        -- Current value divided by 1000000 to get it in ampere
        Current_Now := Float'Value (Get_Line (F)) / 1000000.0;
        Close (F);
        return Current_Now;
    end;
    
    -- Get voltage_now from :/sys/class/power_supply, and convert to volts
    function Get_Voltage_Now return Float is
        F : File_Type; -- File handle
        File_Name : constant String := "/sys/class/power_supply/battery/voltage_now"; -- Filename to read
        Voltage_Now : Float;
    begin
        Open (F, In_File, File_Name);
        -- Voltage value divided by 1000000 to get it in volts
        Voltage_Now := Float'Value (Get_Line (F)) / 1000000.0;
        Close (F);
        return Voltage_Now;
    end;
    
    function Get_Battery_Power return Float is
    begin
        return Get_Voltage_Now * Get_Current_Now;
    end;

end Battery_Power;
