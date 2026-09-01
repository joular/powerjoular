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

-- Write the power data to CSV files
-- A file that can't be written to is reported once
package PowerJoular.CSV is

    -- Write the power of the whole system
    -- Columns: Timestamp, CPU Usage, Total Power, CPU Power, GPU Power
    procedure Save_System (Filename : in String;
                           Data : in Cycle;
                           Overwrite : in Boolean);

    -- Write the power of the monitored process or application
    -- Columns: Timestamp, CPU Usage, CPU Power
    procedure Save_Target (Filename : in String;
                           Data : in Cycle;
                           Overwrite : in Boolean);

end PowerJoular.CSV;
