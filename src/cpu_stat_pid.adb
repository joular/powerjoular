--
--  Copyright (c) 2020-2023, Adel Noureddine, Universit� de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Text_IO; use Ada.Text_IO;
with GNAT.String_Split; use GNAT;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with GNAT.OS_Lib; use GNAT.OS_Lib;

package body CPU_STAT_PID is

    procedure Calculate_PID_Time (PID_Data : in out CPU_STAT_PID_Data; Is_Before : in Boolean) is
        F : File_Type; -- File handle
        File_Name : constant String := "/proc/" & Trim(Integer'Image(PID_Data.PID_Number), Ada.Strings.Left) & "/stat"; -- File name /proc/pid/stat
        Subs : String_Split.Slice_Set; -- Used to slice the read data from stat file
        Seps : constant String := " "; -- Seperator (space) for slicing string
        Utime : Long_Integer; -- User time
        Stime : Long_Integer; -- System time
    begin
        Open (F, In_File, File_Name);
        String_Split.Create (S          => Subs, -- Store sliced data in Subs
                             From       => Get_Line (F), -- Read data to slice. We only need the first line of the stat file
                             Separators => Seps, -- Separator (here space)
                             Mode       => String_Split.Multiple);
        Close (F);

        -- Reading cpu time from /proc/pid/stat
        -- We only need utime and stime (user and system time)
        -- utime is at index 13, stime at index 14 (assuming index starts at 0)
        -- utime  %lu : Amount of time that this process has been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)). This includes guest time, guest_time (time spent running a virtual CPU, see below), so that applications that are not aware of the guest time field do not lose that time from their calculations.
        -- stime  %lu :  Amount of time that this process has been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)).
        -- Example of line: 25152 (java) S 12564 1685 1685 0 -1 1077960704 155132 412 478 2 11617 1816 0 0 20 0 61 0 2001362 3813126144 99139 18446744073709551615 4194304 4196724 140736365379696 140736365362368 140056419567211 0 0 4096 16796879 18446744073709551615 0 0 17 2 0 0 3 0 0 6294960 6295616 13131776 140736365387745 140736365388341 140736365388341 140736365391821 0
        -- fscanf(fp, "%*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %lu %lu", &cpu_process_data->utime, &cpu_process_data->stime);
        Utime := Long_Integer'Value (String_Split.Slice (Subs, 14)); -- Index 13 in file. Slice function starts index at 1, so it is 14
        Stime := Long_Integer'Value (String_Split.Slice (Subs, 15)); -- Index 14 in file. Slice function starts index at 1, so it is 15
        if (Is_Before) then
            PID_Data.Before_Time := Utime + Stime; -- Total time
        else
            PID_Data.After_Time := Utime + Stime; -- Total time
        end if;
    exception
        when others =>
            Put_Line ("Error reading " & File_Name & " file");
            OS_Exit (0);
    end;

end CPU_STAT_PID;
