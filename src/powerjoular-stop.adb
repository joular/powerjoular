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

with GNAT.Ctrl_C;
with Interfaces.C;

with PowerJoular.Platform;

package body PowerJoular.Stop is

    -- Atomic, as the handler runs in another thread on Windows
    Flag : Boolean := False with Atomic;

    -- Only sets the flag, as printing or closing files is not safe from a signal handler
    -- At library level, as GNAT.Ctrl_C requires
    procedure On_Ctrl_C is
    begin
        Flag := True;
    end On_Ctrl_C;

    --------------------------------------------------

    -- The same, for the signals of the OS
    procedure On_Signal (Number : in Interfaces.C.int) with Convention => C;

    procedure On_Signal (Number : in Interfaces.C.int) is
        pragma Unreferenced (Number);
    begin
        Flag := True;
    end On_Signal;

    --------------------------------------------------

    procedure Install is
    begin
        GNAT.Ctrl_C.Install_Handler (On_Ctrl_C'Access);

        -- kill and systemctl stop send SIGTERM, closing the terminal SIGHUP, a closed pipe (powerjoular | head) SIGPIPE
        -- Stop cleanly then too (on macOS, powermetrics would outlive us)
        Platform.Install_Stop_Handler (On_Signal'Access);
    end Install;

    --------------------------------------------------

    procedure Ask is
    begin
        Flag := True;
    end Ask;

    function Asked return Boolean is (Flag);

end PowerJoular.Stop;
