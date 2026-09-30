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

with PowerJoular.Options;

-- Write the power data to CSV files
-- Monitoring a process or an application writes a second file: the CSV file name followed by the PID or the application name
package PowerJoular.CSV is

    -- Set the files to write to, from the command line
    procedure Start (Config : in Options.Settings);

    -- Add one row to each file, or replace their content in overwrite mode
    -- Columns of the system file: Timestamp, CPU Usage, Total Power, CPU Power, GPU Power
    -- Columns of the process or application file: Timestamp, CPU Usage, CPU Power (-1.0000 in both when unreadable)
    -- A file that can't be written to is skipped, and reported once
    procedure Write (Data : in Cycle);

end PowerJoular.CSV;
