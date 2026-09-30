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

-- Print the power data on the terminal
-- On a terminal each measurement is written over the previous one, otherwise (file or pipe) each one gets its own line
package PowerJoular.Terminal is

    -- Check whether the standard output is a terminal that handles escape sequences, and enable them on Windows
    -- Called once, before anything is printed
    procedure Enable_Escape_Sequences;

    function Escapes_Enabled return Boolean;

    -- Show one cycle, of the monitored process or application if any, otherwise of the whole system
    -- An unreadable value is shown as "n/a"
    procedure Show (Data : in Cycle; Target : in Target_Kind; GPU_Available : in Boolean);

    -- End the line left open by the last measurement, before an error message or when stopping
    procedure Close_Line;

end PowerJoular.Terminal;
