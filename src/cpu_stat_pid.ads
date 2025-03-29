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

package CPU_STAT_PID is

    -- Type to store PID CPU stats data
    type CPU_STAT_PID_Data is
        record
            Before_Time : Long_Integer; -- Total time, before monitoring
            After_Time : Long_Integer; -- Total time, after monitoring
            PID_Number : Integer; -- PID to monitor
            Power : Long_Float; -- Power consumption in monitoring cycle for PID
            Monitored_Time : Long_Integer; -- Monitored CPU time in the monitoring cycle
        end record;
    
    -- Calculate PID CPU time
    procedure Calculate_PID_Time (PID_Data : in out CPU_STAT_PID_Data; Is_Before : in Boolean);

end CPU_STAT_PID;
