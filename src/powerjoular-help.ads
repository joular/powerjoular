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

package PowerJoular.Help is

    -- Print help information on the terminal
    procedure Show_Help;

    -- Print only the version number
    procedure Show_Version;

    -- Print what the machine offers and which libraries are used, for the -d option
    procedure Show_System_Info (CPU_Available : in Boolean;
                                GPU_Available : in Boolean;
                                Ring_Buffer_Path : in String;
                                Using_Ring_Buffer : in Boolean);

end PowerJoular.Help;
