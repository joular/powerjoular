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

with Ada.Environment_Variables;
with Ada.Unchecked_Conversion;
with Interfaces; use Interfaces;
with Interfaces.C; use Interfaces.C;
with System; use System;
with System.Storage_Elements; use System.Storage_Elements;

with PowerJoular.Formatting;

-- Nothing else is needed: the shared memory comes from the Windows API, or from the C calls,
-- imported further down in whichever of the two halves of this body is compiled

package body PowerJoular.Ring_Buffer is

    -- How many entries the buffer holds, enough for a reader to fall a few cycles behind and still find them
    Entry_Count : constant := 5;

    -- One entry, laid out the way a C program reading it expects
    -- The sizes are spelled out below so the compiler refuses to build rather than write a layout no reader understands
    type Ring_Entry is
        record
            Timestamp : Unsigned_64 := 0; -- Unix time in seconds
            CPU_Power : IEEE_Float_64 := 0.0; -- total system CPU power, in watts
            GPU_Power : IEEE_Float_64 := 0.0; -- total system GPU power, in watts
            Total_Power : IEEE_Float_64 := 0.0; -- total system power, in watts
            CPU_Usage : IEEE_Float_64 := 0.0; -- total system CPU usage, from 0.0 to 1.0
            PID_App_Power : IEEE_Float_64 := 0.0; -- Power consumption of process or application
        end record
        with Convention => C, Size => 48 * 8;

    type Entry_Array is array (0 .. Entry_Count - 1) of Ring_Entry
        with Convention => C;

    -- The buffer as a whole: the counter of how many cycles have been written, then the entries
    type Shared_Area is
        record
            Head : Unsigned_64 := 0;
            Entries : Entry_Array;
        end record
        with Convention => C, Size => (8 + Entry_Count * 48) * 8;

    -- Size of the buffer in bytes
    Area_Bytes : constant := 8 + Entry_Count * 48;

    type Area_Access is access all Shared_Area;

    function To_Area is new Ada.Unchecked_Conversion (System.Address, Area_Access);

    -- The area once it is mapped, null while it isn't
    Area : Area_Access := null;

    -- How many cycles have been written, held here rather than in the area itself
    -- Any user of the machine can write to the area, so nothing sitting in it is trusted:
    -- the counter that says where the next cycle goes is kept on our side and only ever published outwards
    Head : Unsigned_64 := 0;

    -- Make sure the entry has reached memory before the counter says it is there
    -- Without it, a processor that reorders its writes, as the ARM ones of the Raspberry Pi do, could let a reader see the new counter and the previous entry
    procedure Memory_Barrier;
    pragma Import (Intrinsic, Memory_Barrier, "__sync_synchronize");

    -- Where the area lives, a real file on every OS
    -- On Windows it goes under ProgramData so any user can access it
#if PJ_WINDOWS then
    Area_Path : constant String :=
        Ada.Environment_Variables.Value ("PROGRAMDATA", "C:\ProgramData") & "\joularcorering";
#elsif PJ_LINUX then
    Area_Path : constant String := "/dev/shm/joularcorering";
#else
    Area_Path : constant String := "/tmp/joularcorering";
#end if;

    --------------------------------------------------

    function Path return String is
        (Area_Path);

    --------------------------------------------------

    procedure Write (Data : in Cycle) is
        Position : Natural;
    begin
        if Area = null then
            return;
        end if;

        -- Our own counter says where the next cycle goes, and is raised once the cycle is written
        -- Reading the position back out of the area would let anyone who writes to it steer where we write
        Position := Natural (Head mod Entry_Count);

        Area.Entries (Position) :=
            (Timestamp => Unsigned_64 (PowerJoular.Formatting.Unix_Time),
             CPU_Power => IEEE_Float_64 (Data.CPU_Power),
             GPU_Power => IEEE_Float_64 (Data.GPU_Power),
             Total_Power => IEEE_Float_64 (Data.Total_Power),
             CPU_Usage => IEEE_Float_64 (Data.CPU_Usage),
             PID_App_Power => IEEE_Float_64 (Data.Target_Power));

        Memory_Barrier;

        Head := Head + 1;
        Area.Head := Head;
    exception
        when others =>
            null;
    end Write;

#if PJ_WINDOWS then

    -- Read and write the memory of the object
    PAGE_READWRITE : constant unsigned := 4;
    FILE_MAP_ALL_ACCESS : constant unsigned := 16#F001F#;

    -- What CreateFileA hands back when it could not open what was asked
    INVALID_HANDLE_VALUE : constant System.Address := To_Address (Integer_Address'Last);

    -- Flags for opening the file holding the area
    GENERIC_READ : constant unsigned := 16#8000_0000#;
    GENERIC_WRITE : constant unsigned := 16#4000_0000#;
    
    -- Both share flags matter: without them the reader cannot open the file while we hold it
    FILE_SHARE_READ : constant unsigned := 16#0000_0001#;
    FILE_SHARE_WRITE : constant unsigned := 16#0000_0002#;
    
    -- Open the file that is already there, or create it when it is not, so a second run carries on in the same one
    OPEN_ALWAYS : constant unsigned := 4;
    FILE_ATTRIBUTE_NORMAL : constant unsigned := 16#0000_0080#;

    --  Opens, or creates, the file the area is held in
    function CreateFileA
       (lpFileName : System.Address;
        dwDesiredAccess : unsigned;
        dwShareMode : unsigned;
        lpSecurityAttributes : System.Address;
        dwCreationDisposition : unsigned;
        dwFlagsAndAttributes : unsigned;
        hTemplateFile : System.Address) return System.Address;
    pragma Import (Stdcall, CreateFileA, "CreateFileA");

    function CreateFileMappingA
       (hFile : System.Address;
        lpFileMappingAttributes : System.Address;
        flProtect : unsigned;
        dwMaximumSizeHigh : unsigned;
        dwMaximumSizeLow : unsigned;
        lpName : System.Address) return System.Address;
    pragma Import (Stdcall, CreateFileMappingA, "CreateFileMappingA");

    function MapViewOfFile
       (hFileMappingObject : System.Address;
        dwDesiredAccess : unsigned;
        dwFileOffsetHigh : unsigned;
        dwFileOffsetLow : unsigned;
        dwNumberOfBytesToMap : size_t) return System.Address;
    pragma Import (Stdcall, MapViewOfFile, "MapViewOfFile");

    function UnmapViewOfFile (lpBaseAddress : System.Address) return int;
    pragma Import (Stdcall, UnmapViewOfFile, "UnmapViewOfFile");

    function CloseHandle (hObject : System.Address) return int;
    pragma Import (Stdcall, CloseHandle, "CloseHandle");

    -- The shared memory object, kept until the program stops
    Object : System.Address := System.Null_Address;

    -- The file the area is held in, kept open for as long as the object is
    File : System.Address := INVALID_HANDLE_VALUE;

    --------------------------------------------------

    function Open return Boolean is
        Name : aliased constant char_array := To_C (Area_Path);
        Mapped : System.Address;
    begin
        if Area /= null then
            return True;
        end if;

        File :=
            CreateFileA
                (lpFileName => Name'Address,
                 dwDesiredAccess => GENERIC_READ or GENERIC_WRITE,
                 dwShareMode => FILE_SHARE_READ or FILE_SHARE_WRITE,
                 lpSecurityAttributes => System.Null_Address,
                 dwCreationDisposition => OPEN_ALWAYS,
                 dwFlagsAndAttributes => FILE_ATTRIBUTE_NORMAL,
                 hTemplateFile => System.Null_Address);

        if File = INVALID_HANDLE_VALUE then
            return False;
        end if;

        -- Mapping a file shorter than the size asked for grows it to that size, so a file made just above ends up holding the whole area, and one left by an earlier run is already the right size
        -- The object is left unnamed: the file itself is what a reader looks for
        Object :=
            CreateFileMappingA
                (hFile => File,
                 lpFileMappingAttributes => System.Null_Address,
                 flProtect => PAGE_READWRITE,
                 dwMaximumSizeHigh => 0,
                 dwMaximumSizeLow => unsigned (Area_Bytes),
                 lpName => System.Null_Address);

        if Object = System.Null_Address then
            Close;
            return False;
        end if;

        Mapped :=
            MapViewOfFile
                (hFileMappingObject => Object,
                 dwDesiredAccess => FILE_MAP_ALL_ACCESS,
                 dwFileOffsetHigh => 0,
                 dwFileOffsetLow => 0,
                 dwNumberOfBytesToMap => size_t (Area_Bytes));

        if Mapped = System.Null_Address then
            Close;
            return False;
        end if;

        Area := To_Area (Mapped);

        -- Carry on counting from what is already there, so a reader watching the counter
        -- doesn't see it drop back to zero when a second run takes over
        Head := Area.Head;

        return True;
    exception
        when others =>
            Close;
            return False;
    end Open;

    --------------------------------------------------

    procedure Close is
        Ignored : int;
    begin
        if Area /= null then
            Ignored := UnmapViewOfFile (Area.all'Address);
            Area := null;
        end if;

        if Object /= System.Null_Address then
            Ignored := CloseHandle (Object);
            Object := System.Null_Address;
        end if;

        -- The file stays behind on purpose, holding the last cycles written, so a reader can still pick them up after PowerJoular has stopped, as it can on Linux
        if File /= INVALID_HANDLE_VALUE then
            Ignored := CloseHandle (File);
            File := INVALID_HANDLE_VALUE;
        end if;
    exception
        when others =>
            Area := null;
            Object := System.Null_Address;
            File := INVALID_HANDLE_VALUE;
    end Close;

#else

    -- On Linux the area is a file in /dev/shm, a folder the system keeps in memory and never writes to a disk
    -- Mapping that file is what makes the memory shared: every program mapping it works on the very same pages

    PROT_READ : constant int := 1;
    PROT_WRITE : constant int := 2;
    MAP_SHARED : constant int := 1;

    -- Flags for opening the area
    -- O_NOFOLLOW is the one that matters: the area sits in a folder every user of the machine can write to,
    -- so without it anyone could leave a symbolic link in its place and have PowerJoular, which is usually
    -- run as root, open and write through it into a file of their choosing
    -- The numbers differ between the kernels, hence the two sets
    O_RDWR : constant int := 2;

#if PJ_LINUX then
    O_CREAT : constant int := 8#100#;
    O_NOFOLLOW : constant int := 8#400000#;
#else
    -- macOS and the BSDs
    O_CREAT : constant int := 16#0200#;
    O_NOFOLLOW : constant int := 16#0100#;
#end if;

    -- Anyone may read the area, only its owner may write to it
    -- The mode is handed to open below and then set again on the descriptor: open only applies it to a file it creates, so an area left behind by an earlier run keeps the mode it already had, and an area no reader can open is useless
    Area_Mode : constant unsigned := 8#644#;

    -- What mmap hands back when it fails, which is not the null address but every bit set
    MAP_FAILED : constant System.Address := To_Address (Integer_Address'Last);

    function C_Mmap
       (Address : System.Address;
        Length : size_t;
        Protection : int;
        Flags : int;
        Descriptor : int;
        Offset : long) return System.Address;
    pragma Import (C, C_Mmap, "mmap");

    function C_Munmap (Address : System.Address; Length : size_t) return int;
    pragma Import (C, C_Munmap, "munmap");

    -- open takes the path and the flags, then the mode as a variable argument, and only when it creates the file
    -- C_Variadic_2 says as much, so the mode is passed the way a variable argument is passed rather than the way a plain third argument would be: the two differ on Apple Silicon, where variable arguments go on the stack
    function C_Open (Path : in char_array; Flags : in int; Mode : in unsigned) return int;
    pragma Import (C_Variadic_2, C_Open, "open");

    function C_Ftruncate (Descriptor : in int; Length : in long) return int;
    pragma Import (C, C_Ftruncate, "ftruncate");

    function C_Close (Descriptor : in int) return int;
    pragma Import (C, C_Close, "close");

    function C_Fchmod (Descriptor : in int; Mode : in unsigned) return int;
    pragma Import (C, C_Fchmod, "fchmod");

    --------------------------------------------------

    function Open return Boolean is
        Name : constant char_array := To_C (Area_Path);
        Descriptor : int;
        Mapped : System.Address;
        Ignored : int;
    begin
        if Area /= null then
            return True;
        end if;

        -- Take the file already there when there is one, so a second run carries on writing where the first left off, and make it when there isn't
        -- O_NOFOLLOW turns a symbolic link left in its place into a plain failure rather than a write through it
        Descriptor := C_Open (Name, O_RDWR + O_CREAT + O_NOFOLLOW, Area_Mode);

        if Descriptor < 0 then
            return False;
        end if;

        -- Make sure the area really carries the mode asked for above, so other programs can read it
        Ignored := C_Fchmod (Descriptor, Area_Mode);

        -- The file has to be as big as the area before it is mapped, or reading the mapping would fault
        -- A file already the right size keeps what it holds, counter and entries included
        if C_Ftruncate (Descriptor, long (Area_Bytes)) /= 0 then
            Ignored := C_Close (Descriptor);
            return False;
        end if;

        Mapped :=
            C_Mmap
                (Address => System.Null_Address,
                 Length => size_t (Area_Bytes),
                 Protection => PROT_READ + PROT_WRITE,
                 Flags => MAP_SHARED,
                 Descriptor => Descriptor,
                 Offset => 0);

        Ignored := C_Close (Descriptor);

        if Mapped = MAP_FAILED or else Mapped = System.Null_Address then
            return False;
        end if;

        Area := To_Area (Mapped);

        -- Carry on counting from what is already there, so a reader watching the counter
        -- doesn't see it drop back to zero when a second run takes over
        Head := Area.Head;

        return True;
    exception
        when others =>
            return False;
    end Open;

    --------------------------------------------------

    procedure Close is
        Ignored : int;
    begin
        if Area /= null then
            Ignored := C_Munmap (Area.all'Address, size_t (Area_Bytes));
            Area := null;
        end if;
    exception
        when others =>
            Area := null;
    end Close;

#end if;

end PowerJoular.Ring_Buffer;
