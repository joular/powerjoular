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

with Interfaces.C; use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;

-- Linux, macOS and FreeBSD, told apart by the symbols of CPU Load (see powerjoular.gpr)
package body PowerJoular.Platform is

    use type System.Address;

    -- Flags of open, from fcntl.h
    O_WRONLY : constant := 1;
    O_RDWR : constant := 2;
#if PJ_LINUX then
    O_CREAT : constant := 8#100#;   -- The same on x86 and ARM
    O_EXCL : constant := 8#200#;
    O_APPEND : constant := 8#2000#;
    O_NONBLOCK : constant := 8#4000#;
#if PJ_ARM then
    O_NOFOLLOW : constant := 8#100000#;
#else
    O_NOFOLLOW : constant := 8#400000#;
#end if;
#else
    O_CREAT : constant := 16#0200#;
    O_EXCL : constant := 16#0800#;
    O_APPEND : constant := 16#0008#;
    O_NONBLOCK : constant := 16#0004#;
    O_NOFOLLOW : constant := 16#0100#;
#end if;

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

#if PJ_LINUX then
    -- /dev/shm is kept in memory and never written to a disk
    function Ring_Buffer_Path return String is ("/dev/shm/powerjoular");

    function No_Power_Source_Hint return String is
        ("On a PC or a server, reading RAPL needs root: try 'sudo powerjoular'.");
#elsif PJ_MACOS then
    function Ring_Buffer_Path return String is ("/tmp/powerjoular");

    function No_Power_Source_Hint return String is
        ("On a Mac, reading powermetrics needs root: try 'sudo powerjoular'.");
#else
    -- FreeBSD has no /dev/shm
    function Ring_Buffer_Path return String is ("/tmp/powerjoular");

    function No_Power_Source_Hint return String is
        ("On FreeBSD, reading RAPL needs the cpuctl module and root: try 'sudo kldload cpuctl' and 'sudo powerjoular'.");
#end if;

    --------------------------------------------------

    -- Every POSIX terminal handles escape sequences already
    function Enable_Terminal_Escapes return Boolean is
    begin
        return isatty (Standard_Output) /= 0;
    end Enable_Terminal_Escapes;

    --------------------------------------------------

    function Open_Output (Path : in String; Append : in Boolean) return GNAT.OS_Lib.File_Descriptor is
        Name : constant char_array := To_C (Path);
        Ignored : int;
    begin
        -- O_NOFOLLOW refuses a symbolic link, O_NONBLOCK a FIFO no one reads, which would block the program
        -- A hard link is still followed: Linux refuses to make one to another user's file, macOS and FreeBSD don't (see the README)
        if Append then
            return GNAT.OS_Lib.File_Descriptor (open (Name, O_WRONLY + O_APPEND + O_NOFOLLOW + O_NONBLOCK, 0));
        end if;

        -- As in Create_Shared_File, O_EXCL makes sure the file is a new one and ours
        Ignored := unlink (Name);

        return GNAT.OS_Lib.File_Descriptor (open (Name, O_WRONLY + O_CREAT + O_EXCL, Shared_File_Mode));
    end Open_Output;

    --------------------------------------------------

    function Replace_File (From : in String; To : in String) return Boolean is
        Moved : Boolean;
    begin
        GNAT.OS_Lib.Rename_File (From, To, Moved);
        return Moved;
    end Replace_File;

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

        Descriptor := open (Name, O_RDWR + O_CREAT + O_EXCL, Shared_File_Mode);

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

    --------------------------------------------------

    -- The same numbers on Linux, macOS and FreeBSD
    SIGHUP : constant := 1;
    SIGTERM : constant := 15;

    Stop_Signals : constant array (1 .. 2) of int := (SIGHUP, SIGTERM);

    SIG_IGN : constant System.Address := To_Address (1);

    -- Both return the previous handler
    function signal (signum : int; handler : Signal_Handler) return System.Address
        with Import, Convention => C, External_Name => "signal";

    function signal (signum : int; handler : System.Address) return System.Address
        with Import, Convention => C, External_Name => "signal";

    procedure Install_Stop_Handler (Handler : in Signal_Handler) is
        Previous : System.Address;
    begin
        for Number of Stop_Signals loop
            Previous := signal (Number, Handler);

            if Previous = SIG_IGN then
                Previous := signal (Number, SIG_IGN);
            end if;
        end loop;
    end Install_Stop_Handler;

end PowerJoular.Platform;
