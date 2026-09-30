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
with PowerJoular.Platform;

package body PowerJoular.Terminal is

    Decimals : constant := 2;

    -- Go back to the start of the line and clear it
    Clear_Line : constant String := CR & ESC & "[0K";

    Escapes : Boolean := False;

    -- True once a measurement was printed without an end of line
    Line_Left_Open : Boolean := False;

    --------------------------------------------------

    -- Value followed by its unit, or "n/a" if unreadable
    -- Scale multiplies the value, to print a load from 0.0 to 1.0 as a percentage
    function Reading (Value : in Long_Float; Unit : in String; Scale : in Long_Float := 1.0) return String is
        (if Is_Unreadable (Value) then "n/a" else Image (Scale * Value, Decimals) & Unit);

    --------------------------------------------------

    procedure Enable_Escape_Sequences is
    begin
        Escapes := Platform.Enable_Terminal_Escapes;
    end Enable_Escape_Sequences;

    function Escapes_Enabled return Boolean is (Escapes);

    --------------------------------------------------

    procedure Show (Data : in Cycle; Target : in Target_Kind; GPU_Available : in Boolean) is
    begin
        if Escapes then
            Put (Clear_Line);
        end if;

        case Target is
            when Whole_System =>
                Put ("Total Power: " & Image (Data.Total_Power, Decimals) & " Watts ");
                Put ("(CPU: " & Image (Data.CPU_Power, Decimals) & " W");

                if GPU_Available then
                    Put (", GPU: " & Image (Data.GPU_Power, Decimals) & " W");
                end if;

                Put (")");

            when One_Process | One_Application =>
                Put ((if Target = One_Process then "PID monitoring:" else "Application monitoring:") & HT);

                -- The process next to the whole system, for the load then for the power
                Put ("CPU: " & Reading (Data.Target_Usage, " %", Scale => 100.0));
                Put (" (" & Image (100.0 * Data.CPU_Usage, Decimals) & " %)" & HT);
                Put (Reading (Data.Target_Power, " Watts"));
                Put (" (" & Image (Data.CPU_Power, Decimals) & " Watts)");
        end case;

        if Escapes then
            Line_Left_Open := True;
        else
            New_Line;
        end if;

        -- A pipe or a file is block buffered, so flush every reading
        Flush;
    end Show;

    --------------------------------------------------

    procedure Close_Line is
    begin
        if Line_Left_Open then
            New_Line;
            Line_Left_Open := False;
        end if;
    end Close_Line;

end PowerJoular.Terminal;
