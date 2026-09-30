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
with Interfaces.C; use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;

with PowerJoular.Platform.Constants;

-- Linux and macOS
package body PowerJoular.Platform is

    use type System.Address;

    O_RDWR : constant := 2;

    PROT_READ : constant := 1;
    PROT_WRITE : constant := 2;
    MAP_SHARED : constant := 1;

    -- mmap returns (void *) -1 on failure, not NULL
    MAP_FAILED : constant System.Address := To_Address (Integer_Address'Last);

    -- Readable by everyone, writable by its owner only
    Shared_File_Mode : constant := 8#644#;

    Standard_Output : constant := 1;

    function isatty (fd : int) return int;
    pragma Import (C, isatty, "isatty");

    -- The mode is a variadic argument of open, and variadic arguments are passed differently on Apple Silicon
    function open (path : char_array; flags : int; mode : unsigned) return int;
    pragma Import (C_Variadic_2, open, "open");

    function close (fd : int) return int;
    pragma Import (C, close, "close");

    function unlink (path : char_array) return int;
    pragma Import (C, unlink, "unlink");

    function fchmod (fd : int; mode : unsigned) return int;
    pragma Import (C, fchmod, "fchmod");

    function ftruncate (fd : int; length : long) return int;
    pragma Import (C, ftruncate, "ftruncate");

    function mmap (addr : System.Address; length : size_t; prot : int; flags : int; fd : int; offset : long)
        return System.Address;
    pragma Import (C, mmap, "mmap");

    function munmap (addr : System.Address; length : size_t) return int;
    pragma Import (C, munmap, "munmap");

    --------------------------------------------------

    function Ring_Buffer_Path return String is (Constants.Ring_Buffer_Path);

    function No_Power_Source_Hint return String is (Constants.No_Power_Source_Hint);

    --------------------------------------------------

    -- Every POSIX terminal handles escape sequences already
    function Enable_Terminal_Escapes return Boolean is
    begin
        return isatty (Standard_Output) /= 0;
    end Enable_Terminal_Escapes;

    --------------------------------------------------

    function Is_Symbolic_Link (Path : in String) return Boolean is
    begin
        return GNAT.OS_Lib.Is_Symbolic_Link (Path);
    end Is_Symbolic_Link;

    --------------------------------------------------

    function Create_Shared_File (Path : in String; Size : in Positive) return System.Address is
        Name : constant char_array := To_C (Path);
        Descriptor : int;
        Mapped : System.Address;
        Ignored : int;
    begin
        -- Anyone can write in that folder, so a file left there could be a link or held open by someone else
        -- O_EXCL makes sure the file is a new one and ours, and refuses to follow a symbolic link
        Ignored := unlink (Name);

        Descriptor := open (Name, O_RDWR + Constants.O_CREAT + Constants.O_EXCL, Shared_File_Mode);

        if Descriptor < 0 then
            return System.Null_Address;
        end if;

        -- open applies the umask to the mode, fchmod doesn't
        Ignored := fchmod (Descriptor, Shared_File_Mode);

        -- The file must be as big as the mapping, or accessing the mapping would fault
        if ftruncate (Descriptor, long (Size)) /= 0 then
            Ignored := close (Descriptor);
            return System.Null_Address;
        end if;

        Mapped := mmap (System.Null_Address, size_t (Size), PROT_READ + PROT_WRITE, MAP_SHARED, Descriptor, 0);

        -- The mapping stays valid once the file is closed
        Ignored := close (Descriptor);

        if Mapped = MAP_FAILED then
            return System.Null_Address;
        end if;

        return Mapped;
    end Create_Shared_File;

    --------------------------------------------------

    procedure Unmap_Shared_File (Address : in System.Address; Size : in Positive) is
        Ignored : int;
    begin
        Ignored := munmap (Address, size_t (Size));
    end Unmap_Shared_File;

end PowerJoular.Platform;
