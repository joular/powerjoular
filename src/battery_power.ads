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

package Battery_Power is

    -- Get the battery power consumption of the mobile Linux device
    -- This is calculated as current_now (in microamps) x voltage_now (in microvolts)
    function Get_Battery_Power return Float;

end Battery_Power;
