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

-- Ctrl+C handling: the handler only sets a flag, which the main loop checks
package PowerJoular.Stop is

    -- Replace the default Ctrl+C behaviour, so the program can close its files before exiting
    procedure Install;

    -- Whether Ctrl+C was pressed
    function Asked return Boolean;

end PowerJoular.Stop;
