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
with Interfaces.C; use Interfaces.C;

with PowerJoular.Formatting; use PowerJoular.Formatting;

#if PJ_WINDOWS then
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

    -- Show not available when a reading cannot be read
    Not_Available : constant String := "n/a";

    -- Whether the standard output is a terminal that acts on the escape sequences, worked out once on start up
    -- False until then, so nothing prints a sequence before the question has been asked
    Escapes_Usable : Boolean := False;

    function Escapes_Enabled return Boolean is
       (Escapes_Usable);

    -- Transform one reading into a String ready to print: the value followed by its unit, or Not_Available when it could not be read
    -- Scale multiplies the value first, which is how a load of 0.0 to 1.0 is printed as a percentage
    function Reading (Value : in Long_Float;
                      Unit : in String;
                      Scale : in Long_Float := 1.0) return String is
       (if Is_Unreadable (Value) then Not_Available
        else Image (Scale * Value, Decimals) & Unit);

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
    begin
        Escapes_Usable := False;

        -- Asking for the mode fails when the output is not a console at all, but a file or a pipe, so we do nothing
        if GetConsoleMode (Output, Mode'Access) = 0 then
            return;
        end if;

        -- An older console refuses to act on the escape sequences and would show them as text instead
        -- The refusal is not worth reporting, the display simply falls back to a line per measurement
        Escapes_Usable :=
            SetConsoleMode (Output, Mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING) /= 0;
    exception
        when others =>
            Escapes_Usable := False;
    end Enable_Escape_Sequences;

#else

    -- Tells a terminal apart from a file or a pipe, the standard output being the descriptor numbered 1
    function C_Isatty (Descriptor : in int) return int;
    pragma Import (C, C_Isatty, "isatty");

    Standard_Output : constant int := 1;

    -- Every other terminal acts on the escape sequences already, so there is nothing to turn on
    -- Check whether there is a terminal or not
    procedure Enable_Escape_Sequences is
    begin
        Escapes_Usable := C_Isatty (Standard_Output) /= 0;
    exception
        when others =>
            Escapes_Usable := False;
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
        -- On a terminal this measurement is written over the previous one
        if Escapes_Usable then
            Put (Clear_Line);
        end if;

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
                Put ("CPU: " & Reading (Data.Target_Usage, " %", Scale => 100.0));
                Put (" (" & Image (100.0 * Data.CPU_Usage, Decimals) & " %)" & HT);
                Put (Reading (Data.Target_Power, " Watts"));
                Put (" (" & Image (Data.CPU_Power, Decimals) & " Watts)");
        end case;

        if Escapes_Usable then
            -- The line carries no end of line, so it has to be pushed out by hand to show up at once
            Flush;
            Line_Left_Open := True;
        else
            -- Nothing is going to be written over, so we print a new line
            New_Line;
        end if;
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
