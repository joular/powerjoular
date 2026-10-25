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

with GNAT.OS_Lib;
with Interfaces.C;
with System;

-- Everything that differs between operating systems
-- One body in src/posix (Linux, macOS and FreeBSD) and one in src/windows, powerjoular.gpr picks the folder from PJ_OS
package PowerJoular.Platform is

    -- Path of the shared memory ring buffer
    function Ring_Buffer_Path return String;

    -- How to get a power source working on this OS, printed when none is found
    function No_Power_Source_Hint return String;

    -- Enable escape sequences on the console if needed (Windows)
    -- Returns True if the standard output is a terminal that handles them, False for a file or a pipe
    function Enable_Terminal_Escapes return Boolean;

    -- Open Path to write to, never through a symbolic link, as PowerJoular often runs as root
    -- Append opens a file that exists, at its end; otherwise anything at Path is deleted and a new file created
    -- Returns GNAT.OS_Lib.Invalid_FD on failure
    function Open_Output (Path : in String; Append : in Boolean) return GNAT.OS_Lib.File_Descriptor;

    -- Rename From to To, replacing To if it exists (GNAT's Rename_File fails then on Windows)
    function Replace_File (From : in String; To : in String) return Boolean;

    -- Create a new file of Size bytes at Path, readable by everyone, and map it in shared memory
    -- Anything already at Path is deleted first, so we never write into a file someone else prepared
    -- Returns System.Null_Address on failure
    function Create_Shared_File (Path : in String; Size : in Positive) return System.Address;

    -- Unmap what Create_Shared_File mapped. The file itself stays on disk
    procedure Unmap_Shared_File (Address : in System.Address; Size : in Positive);

    -- A handler for the kill signals the OS sends to end a program, as C expects it
    type Signal_Handler is access procedure (Number : in Interfaces.C.int) with Convention => C;

    -- Call Handler when the OS asks the program to end other than with Ctrl+C: SIGTERM and SIGHUP on POSIX, nothing on Windows
    -- A signal nohup or the shell set to be ignored stays ignored, so a run in the background outlives its terminal
    procedure Install_Stop_Handler (Handler : in Signal_Handler);

end PowerJoular.Platform;
