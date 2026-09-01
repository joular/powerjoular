--
--  Copyright (c) 2020-2026, Adel Noureddine.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

-- PowerJoular monitors, in real time, the power consumption of the system and of the software running on it
-- The hardware energy readings come from the Joular Core library, and the CPU load readings from the CPU Load library
package PowerJoular is

    -- Version of the program
    -- Keep it the same as the version in alire.toml
    Version : constant String := "2.0.0";

    -- Time between two measurements
    Cycle_Interval : constant Duration := 1.0;

    -- What we monitor (the whole system is always monitored)
    type Target_Kind is
       (Whole_System, -- Entire system and nothing else
        One_Process, -- One process, given by its number
        One_Application -- One application, given by its name (all of its processes, tracking creation/destruction)
       );

    -- One cycle of measurements, filled by the monitoring loop
    type Cycle is
        record
            -- Total system CPU usage
            CPU_Usage : Long_Float := 0.0;

            -- CPU usage of the monitored process or application
            -- Always zero when only the whole system is monitored
            Target_Usage : Long_Float := 0.0;

            -- Power drawn over the cycle, in watts
            CPU_Power : Long_Float := 0.0;
            GPU_Power : Long_Float := 0.0;
            Total_Power : Long_Float := 0.0;

            -- CPU power consumption of the monitored process or application
            -- Always zero when only the whole system is monitored
            Target_Power : Long_Float := 0.0;
        end record;

end PowerJoular;
