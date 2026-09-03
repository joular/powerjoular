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

with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Text_IO; use Ada.Text_IO;

with PowerJoular.Formatting; use PowerJoular.Formatting;

#if PJ_WINDOWS then
with Interfaces.C; use Interfaces.C;
with System;
#end if;

package body PowerJoular.Terminal is

    -- Number of digits after the period to print
    Decimals : constant := 2;

    -- Go back to the start of the line and wipe existing text, so this measurement replaces the previous one
    Clear_Line : constant String := CR & ESC & "[0K";

    -- Set once a measurement has been written, as that line carries no end of line of its own
    -- and anything printed after it has to start one first
    Line_Left_Open : Boolean := False;

    --------------------------------------------------

#if PJ_WINDOWS then

    -- The console prints the escape sequences as text until it is told to act on them instead
    ENABLE_VIRTUAL_TERMINAL_PROCESSING : constant unsigned := 16#0004#;

    -- Which of its own handles to ask Windows for, the standard output being the handle numbered -11
    STD_OUTPUT_HANDLE : constant unsigned := 16#FFFF_FFF5#;

    function GetStdHandle (nStdHandle : unsigned) return System.Address;
    pragma Import (Stdcall, GetStdHandle, "GetStdHandle");

    function GetConsoleMode (hConsoleHandle : System.Address; lpMode : access unsigned) return int;
    pragma Import (Stdcall, GetConsoleMode, "GetConsoleMode");

    function SetConsoleMode (hConsoleHandle : System.Address; dwMode : unsigned) return int;
    pragma Import (Stdcall, SetConsoleMode, "SetConsoleMode");

    procedure Enable_Escape_Sequences is
        Output : constant System.Address := GetStdHandle (STD_OUTPUT_HANDLE);
        Mode : aliased unsigned := 0;
        Ignored : int;
    begin
        -- Asking for the mode fails when the output is not a console at all, but a file or a pipe, so we do nothing
        if GetConsoleMode (Output, Mode'Access) = 0 then
            return;
        end if;

        -- If a console refuses to act on the escape sequences, the don't report the refusal as it is just a additional cosmetic thing in PowerJoular
        -- So on an older Windows terminal, it will shows them as text
        Ignored := SetConsoleMode (Output, Mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    exception
        when others =>
            null;
    end Enable_Escape_Sequences;

#else

    -- Every other terminal acts on the escape sequences already
    procedure Enable_Escape_Sequences is
    begin
        null;
    end Enable_Escape_Sequences;

#end if;

    --------------------------------------------------

    procedure Show (Data : in Cycle;
                    Target : in Target_Kind;
                    Previous_Total_Power : in Long_Float;
                    GPU_Available : in Boolean) is

        Difference : constant Long_Float := Data.Total_Power - Previous_Total_Power;
        Arrow : constant String := (if Difference >= 0.0 then "/\ " else "\/ ");
    begin
        Put (Clear_Line);

        case Target is
            when Whole_System =>
                Put ("Total Power: " & Image (Data.Total_Power, Decimals) & " Watts ");
                Put ("(CPU: " & Image (Data.CPU_Power, Decimals) & " W");

                if GPU_Available then
                    Put (", GPU: " & Image (Data.GPU_Power, Decimals) & " W)" & HT);
                else
                    Put (")" & HT);
                end if;

                Put (Arrow & Image (Difference, Decimals) & " Watts");

            when One_Process | One_Application =>
                Put ((if Target = One_Process
                      then "PID monitoring:" & HT
                      else "Application monitoring:" & HT));

                -- The load of the process next to the load of the whole machine, then the same for the power
                Put ("CPU: " & Image (100.0 * Data.Target_Usage, Decimals) & " %");
                Put (" (" & Image (100.0 * Data.CPU_Usage, Decimals) & " %)" & HT);
                Put (Image (Data.Target_Power, Decimals) & " Watts");
                Put (" (" & Image (Data.CPU_Power, Decimals) & " Watts)");
        end case;

        -- The line carries no end of line, so it has to be pushed out by hand to show up at once
        Flush;

        Line_Left_Open := True;
    end Show;

    --------------------------------------------------

    procedure Close_Line is
    begin
        -- A measurement is printed without an end of line, so close that line before leaving
        -- There is none to close when the program is stopped before the first measurement lands
        if Line_Left_Open then
            New_Line;
            Line_Left_Open := False;
        end if;
    end Close_Line;

end PowerJoular.Terminal;
