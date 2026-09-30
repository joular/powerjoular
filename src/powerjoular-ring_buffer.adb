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

with Ada.Unchecked_Conversion;
with Interfaces; use Interfaces;
with System;

with PowerJoular.Platform;

package body PowerJoular.Ring_Buffer is

    use type System.Address;

    Entry_Count : constant := 5;

    -- The sizes are given so the build fails rather than produce a layout readers don't expect
    type Ring_Entry is
        record
            Timestamp : Unsigned_64 := 0;
            CPU_Power : IEEE_Float_64 := 0.0;
            GPU_Power : IEEE_Float_64 := 0.0;
            Total_Power : IEEE_Float_64 := 0.0;
            CPU_Usage : IEEE_Float_64 := 0.0;
            Target_Power : IEEE_Float_64 := 0.0;
        end record
        with Convention => C, Size => 48 * 8;

    type Entry_Array is array (0 .. Entry_Count - 1) of Ring_Entry
        with Convention => C;

    -- Volatile, as other programs read this memory
    type Shared_Area is
        record
            Head : Unsigned_64 := 0;
            Entries : Entry_Array;
        end record
        with Convention => C, Volatile, Size => (8 + Entry_Count * 48) * 8;

    Area_Size : constant Positive := Shared_Area'Size / System.Storage_Unit;

    type Area_Access is access all Shared_Area;

    function To_Area is new Ada.Unchecked_Conversion (System.Address, Area_Access);

    -- null while the ring buffer is not open
    Area : Area_Access := null;

    -- Number of cycles written, kept here rather than read back from the shared memory
    Head : Unsigned_64 := 0;

    -- CPUs that reorder writes (e.g. ARM) could let a reader see the new counter with the old entry
    procedure Memory_Barrier;
    pragma Import (Intrinsic, Memory_Barrier, "__sync_synchronize");

    --------------------------------------------------

    function Path return String is (Platform.Ring_Buffer_Path);

    --------------------------------------------------

    function Open return Boolean is
        Mapped : System.Address;
    begin
        if Area = null then
            Mapped := Platform.Create_Shared_File (Path, Area_Size);

            if Mapped /= System.Null_Address then
                Area := To_Area (Mapped);
                Head := 0;
            end if;
        end if;

        return Area /= null;
    end Open;

    --------------------------------------------------

    procedure Write (Data : in Cycle) is
    begin
        if Area = null then
            return;
        end if;

        Area.Entries (Natural (Head mod Entry_Count)) :=
            (Timestamp => Unsigned_64 (Data.Time),
             CPU_Power => IEEE_Float_64 (Data.CPU_Power),
             GPU_Power => IEEE_Float_64 (Data.GPU_Power),
             Total_Power => IEEE_Float_64 (Data.Total_Power),
             CPU_Usage => IEEE_Float_64 (Data.CPU_Usage),
             Target_Power => IEEE_Float_64 (Data.Target_Power));

        Memory_Barrier;

        Head := Head + 1;
        Area.Head := Head;
    end Write;

    --------------------------------------------------

    procedure Close is
    begin
        if Area /= null then
            Platform.Unmap_Shared_File (Area.all'Address, Area_Size);
            Area := null;
        end if;
    end Close;

end PowerJoular.Ring_Buffer;
