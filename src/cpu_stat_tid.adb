--
--  Copyright (c) 2020-2024, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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

with GNAT.Expect; use GNAT.Expect;
with Ada.Exceptions; use Ada.Exceptions;

with CPU_STAT_PID; use CPU_STAT_PID;

package body CPU_STAT_TID is

    -- This helper function retrieves the CPU time for a specific TID of a given PID
    function Get_TID_Time(PID : Positive; TID : Positive) return Long_Integer is
        F : File_Type;
        File_Name : constant String := "/proc/" & Trim(Integer'Image(PID), Ada.Strings.Left) & "/task/" & Trim(Integer'Image(TID), Ada.Strings.Left) & "/stat";
        Subs : String_Split.Slice_Set;
        Seps : constant String := " ";
        Utime : Long_Integer;
        Stime : Long_Integer;
        Sum_Time : Long_Integer;
    begin
        Open (F, In_File, File_Name);
        String_Split.Create (
            S => Subs,
            From => Get_Line (F),
            Separators => Seps,
            Mode => String_Split.Multiple);
        Close (F);

        -- Reading utime and stime
        Utime := Long_Integer'Value (String_Split.Slice (Subs, 14));
        Stime := Long_Integer'Value (String_Split.Slice (Subs, 15));
        Sum_Time := Utime + Stime;
        return Sum_Time;
    exception
        when NAME_ERROR | STATUS_ERROR =>
            Put_Line ("Error opening or reading the file: " & File_Name);
            return 0;
        when DATA_ERROR | NUMERIC_ERROR =>
            Put_Line ("Error converting data from the file: " & File_Name);
            return 0;
        when others =>
            Put_Line ("Unknown error processing the file: " & File_Name);
            return 0;
    end Get_TID_Time;


    -- Calculate PID Time using TID instead of PID directly
    procedure Calculate_PID_Time_TID (PID_Data : in out CPU_STAT_PID_Data; Is_Before : in Boolean) is
        Task_Directory : constant String := "/proc/" & Trim(Integer'Image(PID_Data.PID_Number), Ada.Strings.Left) & "/task";
        Command : constant String := "ls " & Task_Directory;
        Args       : Argument_List_Access;
        Status     : aliased Integer;
        Subs : String_Split.Slice_Set; -- Used to slice the read data from stat file
        Seps : constant String := String'(1 => Character'Val (10)); -- Newline for slicing string
        Slice_number_count : String_Split.Slice_Number;
        Loop_I : Integer;
        TID_Number : Integer;
        TID_Counter : Integer := 0;
        TID_Total_Time : Long_Integer := 0;
        type TID_Array_Int is array (1..100) of Integer;
        TID_Array : TID_Array_Int; -- Array of all TIDs of the application
    begin
        Args := Argument_String_To_List (Command);
        TID_Array := (others => -1);
        declare
            Response : String :=
              Get_Command_Output
                (Command   => Args (Args'First).all,
                 Arguments => Args (Args'First + 1 .. Args'Last),
                 Input     => "",
                 Status    => Status'Access);
        begin
            Free (Args);
            String_Split.Create (S          => Subs, -- Store sliced data in Subs
                                 From       => Response, -- Read data to slice
                                 Separators => Seps, -- Separator (here space)
                                 Mode       => String_Split.Multiple);
            Slice_number_count := String_Split.Slice_Count (Subs);

            for I in 1 .. Slice_number_count loop
                Loop_I := Integer'Value (String_Split.Slice_Number'Image (I));
                TID_Array(Loop_I) := Integer'Value (String_Split.Slice (Subs, I));
                TID_Counter := TID_Counter + 1;
            end loop;
        end;

        for I in 1 .. TID_Counter loop
            if TID_Array(I) /= -1 then
                TID_Number := TID_Array (I);
                TID_Total_Time := TID_Total_Time + Get_TID_Time (PID_Data.PID_Number, TID_Number);
            end if;
        end loop;
        if (Is_Before) then
            PID_Data.Before_Time := TID_Total_Time;
        else
            PID_Data.After_Time := TID_Total_Time;
            PID_Data.Monitored_Time := PID_Data.After_Time - PID_Data.Before_Time;
        end if;
    exception
        when NAME_ERROR | STATUS_ERROR =>
            Put_Line ("Error dealing with files in /proc/" & Trim(Integer'Image(PID_Data.PID_Number), Ada.Strings.Left) & "/task directory");
            OS_Exit (0);
        when DATA_ERROR =>
            Put_Line ("Error related to data formatting or I/O");
            OS_Exit (0);
        when E : NUMERIC_ERROR =>
            Put_Line ("Arithmetic error encountered");
            Put_Line (Exception_Message (E));
            OS_Exit (0);
        when others =>
            Put_Line ("Unknown error processing /proc/" & Trim(Integer'Image(PID_Data.PID_Number), Ada.Strings.Left) & "/task directory");
            OS_Exit (0);
    end Calculate_PID_Time_TID;

end CPU_STAT_TID;
