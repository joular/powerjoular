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

with System;

-- Everything that differs between operating systems
-- One body in src/posix (Linux and macOS) and one in src/windows, powerjoular.gpr picks the folder from PJ_OS
package PowerJoular.Platform is

    -- Path of the shared memory ring buffer
    function Ring_Buffer_Path return String;

    -- How to get a power source working on this OS, printed when none is found
    function No_Power_Source_Hint return String;

    -- Enable escape sequences on the console if needed (Windows)
    -- Returns True if the standard output is a terminal that handles them, False for a file or a pipe
    function Enable_Terminal_Escapes return Boolean;

    -- Whether Path is a symbolic link (or any reparse point on Windows)
    function Is_Symbolic_Link (Path : in String) return Boolean;

    -- Create a new file of Size bytes at Path, readable by everyone, and map it in shared memory
    -- Anything already at Path is deleted first, so we never write into a file someone else prepared
    -- Returns System.Null_Address on failure
    function Create_Shared_File (Path : in String; Size : in Positive) return System.Address;

    -- Unmap what Create_Shared_File mapped. The file itself stays on disk
    procedure Unmap_Shared_File (Address : in System.Address; Size : in Positive);

end PowerJoular.Platform;
