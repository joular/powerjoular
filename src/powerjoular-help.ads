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

package PowerJoular.Help is

    -- Print help information on the terminal
    procedure Show_Help;

    -- Print only the version number
    procedure Show_Version;

    -- Print the versions and what the machine offers, for the -d option
    procedure Show_System_Info (Config : in Options.Settings;
                                CPU_Available : in Boolean;
                                GPU_Available : in Boolean);

end PowerJoular.Help;
