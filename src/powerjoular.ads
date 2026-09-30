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
-- Hardware readings come from the Joular Core library, CPU load readings from the CPU Load library
package PowerJoular is

    -- Keep it the same as the version in alire.toml
    Version : constant String := "2.0.0";

    Cycle_Interval : constant Duration := 1.0;

    -- A load or a power that could not be read (process gone, or access refused)
    -- Not 0.0, which is a real reading of no load
    Unreadable : constant Long_Float := -1.0;

    function Is_Unreadable (Value : in Long_Float) return Boolean is (Value <= Unreadable);

    -- What we monitor, on top of the whole system which is always monitored
    type Target_Kind is
       (Whole_System, -- Entire system and nothing else
        One_Process, -- One process, given by its PID
        One_Application -- Every process of one application, given by its name
       );

    -- One cycle of measurements
    type Cycle is
        record
            -- Unix time, in seconds, of the measurement
            Time : Long_Long_Integer := 0;

            -- System CPU usage, from 0.0 to 1.0
            CPU_Usage : Long_Float := 0.0;

            -- CPU usage of the monitored process or application
            -- Zero when only the whole system is monitored, Unreadable when it could not be read
            Target_Usage : Long_Float := 0.0;

            -- Power in watts
            CPU_Power : Long_Float := 0.0;
            GPU_Power : Long_Float := 0.0;
            Total_Power : Long_Float := 0.0;

            -- CPU power of the monitored process or application, in watts
            -- Zero when only the whole system is monitored, Unreadable when its usage could not be read
            Target_Power : Long_Float := 0.0;
        end record;

end PowerJoular;
