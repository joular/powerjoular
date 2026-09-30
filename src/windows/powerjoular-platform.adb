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
with Interfaces.C; use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;

package body PowerJoular.Platform is

    use type System.Address;

    -- Handles are pointers, and INVALID_HANDLE_VALUE is (HANDLE) -1
    subtype HANDLE is System.Address;
    INVALID_HANDLE_VALUE : constant HANDLE := To_Address (Integer_Address'Last);

    STD_OUTPUT_HANDLE : constant unsigned := 16#FFFF_FFF5#; -- (DWORD) -11
    ENABLE_VIRTUAL_TERMINAL_PROCESSING : constant unsigned := 16#0004#;

    FILE_ATTRIBUTE_REPARSE_POINT : constant unsigned := 16#0000_0400#;
    INVALID_FILE_ATTRIBUTES : constant unsigned := 16#FFFF_FFFF#;

    GENERIC_READ : constant unsigned := 16#8000_0000#;
    GENERIC_WRITE : constant unsigned := 16#4000_0000#;
    FILE_SHARE_READ : constant unsigned := 16#0000_0001#;
    FILE_SHARE_WRITE : constant unsigned := 16#0000_0002#;
    CREATE_NEW : constant unsigned := 1;
    FILE_ATTRIBUTE_NORMAL : constant unsigned := 16#0000_0080#;

    PAGE_READWRITE : constant unsigned := 4;
    FILE_MAP_ALL_ACCESS : constant unsigned := 16#000F_001F#;

    function GetStdHandle (nStdHandle : unsigned) return HANDLE;
    pragma Import (Stdcall, GetStdHandle, "GetStdHandle");

    function GetConsoleMode (hConsoleHandle : HANDLE; lpMode : access unsigned) return int;
    pragma Import (Stdcall, GetConsoleMode, "GetConsoleMode");

    function SetConsoleMode (hConsoleHandle : HANDLE; dwMode : unsigned) return int;
    pragma Import (Stdcall, SetConsoleMode, "SetConsoleMode");

    function GetFileAttributesA (lpFileName : char_array) return unsigned;
    pragma Import (Stdcall, GetFileAttributesA, "GetFileAttributesA");

    function DeleteFileA (lpFileName : char_array) return int;
    pragma Import (Stdcall, DeleteFileA, "DeleteFileA");

    function CreateFileA
       (lpFileName : char_array;
        dwDesiredAccess : unsigned;
        dwShareMode : unsigned;
        lpSecurityAttributes : System.Address;
        dwCreationDisposition : unsigned;
        dwFlagsAndAttributes : unsigned;
        hTemplateFile : HANDLE) return HANDLE;
    pragma Import (Stdcall, CreateFileA, "CreateFileA");

    function CreateFileMappingA
       (hFile : HANDLE;
        lpFileMappingAttributes : System.Address;
        flProtect : unsigned;
        dwMaximumSizeHigh : unsigned;
        dwMaximumSizeLow : unsigned;
        lpName : System.Address) return HANDLE;
    pragma Import (Stdcall, CreateFileMappingA, "CreateFileMappingA");

    function MapViewOfFile
       (hFileMappingObject : HANDLE;
        dwDesiredAccess : unsigned;
        dwFileOffsetHigh : unsigned;
        dwFileOffsetLow : unsigned;
        dwNumberOfBytesToMap : size_t) return System.Address;
    pragma Import (Stdcall, MapViewOfFile, "MapViewOfFile");

    function UnmapViewOfFile (lpBaseAddress : System.Address) return int;
    pragma Import (Stdcall, UnmapViewOfFile, "UnmapViewOfFile");

    function CloseHandle (hObject : HANDLE) return int;
    pragma Import (Stdcall, CloseHandle, "CloseHandle");

    -- The shared file and its mapping object, kept open while the file is mapped
    Shared_File : HANDLE := INVALID_HANDLE_VALUE;
    Mapping : HANDLE := System.Null_Address;

    --------------------------------------------------

    -- ProgramData is readable by every user
    function Ring_Buffer_Path return String is
        (Ada.Environment_Variables.Value ("PROGRAMDATA", "C:\ProgramData") & "\powerjoular");

    function No_Power_Source_Hint return String is
        ("On Windows, Energy Meter Interface (EMI) was not found or does not measure the processor." & ASCII.LF
         & "Install the PawnIO driver (https://pawnio.eu) and run this from a terminal with administrative rights,"
         & " or Hubblo's RAPL driver, which doesn't require admin rights.");

    --------------------------------------------------

    function Enable_Terminal_Escapes return Boolean is
        Output : constant HANDLE := GetStdHandle (STD_OUTPUT_HANDLE);
        Mode : aliased unsigned := 0;
    begin
        -- Fails when the output is a file or a pipe
        if GetConsoleMode (Output, Mode'Access) = 0 then
            return False;
        end if;

        -- Older consoles refuse, and would print the escape sequences as text
        return SetConsoleMode (Output, Mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING) /= 0;
    end Enable_Terminal_Escapes;

    --------------------------------------------------

    -- Symbolic links and junctions are both reparse points
    function Is_Symbolic_Link (Path : in String) return Boolean is
        Attributes : constant unsigned := GetFileAttributesA (To_C (Path));
    begin
        return Attributes /= INVALID_FILE_ATTRIBUTES
               and then (Attributes and FILE_ATTRIBUTE_REPARSE_POINT) /= 0;
    end Is_Symbolic_Link;

    --------------------------------------------------

    procedure Close_Handles is
        Ignored : int;
    begin
        if Mapping /= System.Null_Address then
            Ignored := CloseHandle (Mapping);
            Mapping := System.Null_Address;
        end if;

        if Shared_File /= INVALID_HANDLE_VALUE then
            Ignored := CloseHandle (Shared_File);
            Shared_File := INVALID_HANDLE_VALUE;
        end if;
    end Close_Handles;

    --------------------------------------------------

    function Create_Shared_File (Path : in String; Size : in Positive) return System.Address is
        Name : constant char_array := To_C (Path);
        Mapped : System.Address;
        Ignored : int;
    begin
        -- Any user can create files in ProgramData, so a file left there could be a link
        -- CREATE_NEW makes sure the file is a new one and ours
        Ignored := DeleteFileA (Name);

        Shared_File :=
            CreateFileA
                (lpFileName => Name,
                 dwDesiredAccess => GENERIC_READ or GENERIC_WRITE,
                 dwShareMode => FILE_SHARE_READ or FILE_SHARE_WRITE,
                 lpSecurityAttributes => System.Null_Address,
                 dwCreationDisposition => CREATE_NEW,
                 dwFlagsAndAttributes => FILE_ATTRIBUTE_NORMAL,
                 hTemplateFile => System.Null_Address);

        if Shared_File = INVALID_HANDLE_VALUE then
            return System.Null_Address;
        end if;

        -- Mapping more bytes than the file holds grows the file to that size
        Mapping :=
            CreateFileMappingA
                (hFile => Shared_File,
                 lpFileMappingAttributes => System.Null_Address,
                 flProtect => PAGE_READWRITE,
                 dwMaximumSizeHigh => 0,
                 dwMaximumSizeLow => unsigned (Size),
                 lpName => System.Null_Address);

        if Mapping = System.Null_Address then
            Close_Handles;
            return System.Null_Address;
        end if;

        Mapped := MapViewOfFile (Mapping, FILE_MAP_ALL_ACCESS, 0, 0, size_t (Size));

        if Mapped = System.Null_Address then
            Close_Handles;
        end if;

        return Mapped;
    end Create_Shared_File;

    --------------------------------------------------

    procedure Unmap_Shared_File (Address : in System.Address; Size : in Positive) is
        pragma Unreferenced (Size);
        Ignored : int;
    begin
        Ignored := UnmapViewOfFile (Address);
        Close_Handles;
    end Unmap_Shared_File;

end PowerJoular.Platform;
