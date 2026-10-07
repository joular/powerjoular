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
#if not PJ_WINDOWS then
with Interfaces.C;
with System;
#end if;

package body PowerJoular.Stop is

    -- Atomic, as the handler runs in another thread on Windows
    Flag : Boolean := False with Atomic;

    -- Only sets the flag, as printing or closing files is not safe from a signal handler
    -- At library level, as GNAT.Ctrl_C requires
    procedure On_Ctrl_C is
    begin
        Flag := True;
    end On_Ctrl_C;

#if not PJ_WINDOWS then
    --------------------------------------------------

    -- The same numbers on Linux, macOS and FreeBSD
    SIGHUP : constant := 1;
    SIGTERM : constant := 15;

    procedure On_Signal (Number : in Interfaces.C.int) with Convention => C;

    procedure On_Signal (Number : in Interfaces.C.int) is
        pragma Unreferenced (Number);
    begin
        Flag := True;
    end On_Signal;

    type Signal_Handler is access procedure (Number : in Interfaces.C.int) with Convention => C;

    -- Returns the previous handler, unused here
    function Signal (Number : in Interfaces.C.int; Handler : in Signal_Handler) return System.Address
        with Import, Convention => C, External_Name => "signal";
#end if;

    --------------------------------------------------

    procedure Install is
    begin
        GNAT.Ctrl_C.Install_Handler (On_Ctrl_C'Access);

#if not PJ_WINDOWS then
        -- kill and systemctl stop send SIGTERM, closing the terminal SIGHUP: stop cleanly then too (on macOS, powermetrics would outlive us)
        declare
            Ignored : System.Address;
        begin
            Ignored := Signal (SIGTERM, On_Signal'Access);
            Ignored := Signal (SIGHUP, On_Signal'Access);
        end;
#end if;
    end Install;

    --------------------------------------------------

    function Asked return Boolean is (Flag);

end PowerJoular.Stop;
