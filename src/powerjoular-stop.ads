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

-- Stop requests: Ctrl+C, and SIGTERM and SIGHUP outside Windows. The handler only sets a flag, which the main loop checks
package PowerJoular.Stop is

    -- Replace the default behaviour of these signals, so the program can close its files and sources before exiting
    procedure Install;

    -- Whether a stop was asked
    function Asked return Boolean;

end PowerJoular.Stop;
