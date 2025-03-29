--
--  Copyright (c) 2020-2025, Adel Noureddine, Universit� de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package CPU_STAT_App is
    
    -- Type for PID arrays, max 100 items
    -- We will only monitoring 100 process at max per application
    type PID_Array_Int is array (1..100) of Integer;

    -- Type to store PID CPU stats data
    type CPU_STAT_App_Data is
        record
            Before_Time : Long_Integer; -- Total time, before monitoring
            After_Time : Long_Integer; -- Total time, after monitoring
            App_Name : Unbounded_String; -- App name to monitor
            Power : Long_Float; -- Power consumption in monitoring cycle for PID
            Monitored_Time : Long_Integer; -- Monitored CPU time in the monitoring cycle
            PID_Array : PID_Array_Int; -- Array of all PIDs of the application
        end record;
    
    -- Calculate App CPU time
    procedure Calculate_App_Time (App_Data : in out CPU_STAT_App_Data; Is_Before : in Boolean);
    
    -- Update PID array for the monitored application
    procedure Update_PID_Array (App_Data : in out CPU_STAT_App_Data);

end CPU_STAT_App;
