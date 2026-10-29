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

-- Print the power data on the terminal
-- On a terminal each measurement is written over the previous one, with meters, otherwise (file or pipe) each one gets its own line of plain text
-- With -i, a terminal shows it on its whole screen instead (powerjoular-terminal-screen.adb)
package PowerJoular.Terminal is

    -- Check whether the standard output is a terminal that handles escape sequences, and enable them on Windows
    -- Called once, before anything is printed
    procedure Enable_Escape_Sequences;

    function Escapes_Enabled return Boolean;

    -- Text in the colour of an escape Code (e.g. "1;38;5;33"), or plain when escapes are off or NO_COLOR is set
    function Colour (Text : in String; Code : in String) return String;

    -- The name and the version, in the colours of the logo on a terminal
    function Banner return String;

    -- Get a terminal ready for the live line, and show the banner, so a file or a pipe gets the measurements alone
    procedure Start (Config : in Options.Settings);

    -- Show one cycle, of the monitored process or application if any, otherwise of the whole system
    -- An unreadable value is shown as "n/a"
    -- Config is the one main ends up with: a ring buffer that failed to open is off in it
    procedure Show (Data : in Cycle; Config : in Options.Settings; CPU_Available, GPU_Available : in Boolean);

    -- Print a message on the standard error after "powerjoular: ", then Detail on its own line if any
    -- While the whole screen is shown, both are held and printed when it closes
    procedure Report (Text : in String; Detail : in String := "");

    -- End the line or close the whole screen, and give the terminal back as Start found it
    procedure Stop;

end PowerJoular.Terminal;
