--
--  Copyright (c) 2020-2023, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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
with GNAT.OS_Lib; use GNAT.OS_Lib;

package body CPU_Cycles is

    procedure Calculate_CPU_Cycles (CPU_Data : in out CPU_Cycles_Data) is
        F : File_Type; -- File handle
        File_Name : constant String := "/proc/stat"; -- Filename to read
        Subs : String_Split.Slice_Set; -- Used to slice the read data from stat file
        Seps : constant String := " "; -- Seperator (space) for slicing string
    begin
        Open (F, In_File, File_Name);
        String_Split.Create (S          => Subs, -- Store sliced data in Subs
                             From       => Get_Line (F), -- Read data to slice. We only need the first line of the stat file
                             Separators => Seps, -- Separator (here space)
                             Mode       => String_Split.Multiple);
        Close (F);

        -- We need to read values at index 1, 2, 3 and 4 (assuming index starts at 0)
        -- Example of line: cpu  83141 56 28074 2909632 3452 10196 3416 0 0 0
        CPU_Data.cuser := Long_Integer'Value (String_Split.Slice (Subs, 2)); -- Index 1 in file. Slice function starts index at 1, so it is 2
        CPU_Data.cnice := Long_Integer'Value (String_Split.Slice (Subs, 3)); -- Index 2 in file. Slice function starts index at 1, so it is 3
        CPU_Data.csystem := Long_Integer'Value (String_Split.Slice (Subs, 4)); -- Index 3 in file. Slice function starts index at 1, so it is 4
        CPU_Data.cidle := Long_Integer'Value (String_Split.Slice (Subs, 5)); -- Index 4 in file. Slice function starts index at 1, so it is 5
        CPU_Data.cbusy := CPU_Data.cuser + CPU_Data.cnice + CPU_Data.csystem; --- cbusy time
        CPU_Data.ctotal := CPU_Data.cuser + CPU_Data.cnice + CPU_Data.csystem + CPU_Data.cidle; -- total time
    exception
        when others =>
            Put_Line ("Error reading " & File_Name & " file");
            OS_Exit (0);
    end;

end CPU_Cycles;
