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
-- Each measurement is written over the previous one, so the display stays on a single line
package PowerJoular.Terminal is

    -- Show one cycle
    -- Monitoring a process or an application shows that process or application, otherwise the whole system is shown
    procedure Show (Data : in Cycle;
                    Target : in Target_Kind;
                    Previous_Total_Power : in Long_Float;
                    GPU_Available : in Boolean);

    -- End the line the last measurement left open, so the shell prompt starts on a line of its own
    -- Called when the program exits
    procedure Close_Line;

end PowerJoular.Terminal;
