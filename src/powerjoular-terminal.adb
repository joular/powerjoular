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
with Ada.Environment_Variables;
with Ada.IO_Exceptions;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Text_IO; use Ada.Text_IO;
with GNAT.OS_Lib;

with CPU_Load;

with PowerJoular.Formatting; use PowerJoular.Formatting;
with PowerJoular.Platform;
with PowerJoular.Stop;

package body PowerJoular.Terminal is

    Decimals : constant := 2;

    -- Go back to the start of the line and clear it
    Clear_Line : constant String := CR & ESC & "[0K";

    -- Turn the wrapping off while the live line is written, so a window narrower than it cuts it at the edge
    -- A wrapped line would leave its first part behind at every rewrite
    No_Wrap : constant String := ESC & "[?7l";
    Wrap : constant String := ESC & "[?7h";

    Escapes : Boolean := False;

    -- A NO_COLOR that is set and not empty asks for no colours (no-color.org)
    Colours : constant Boolean := Ada.Environment_Variables.Value ("NO_COLOR", "") = "";

    -- True when the terminal shows UTF-8, for the blocks of the meters
    Unicode : Boolean := False;

    -- PID or name of the application monitored, the name cut so the live line keeps within 72 columns
    App_Name_Width : constant := 9;
    Name : Unbounded_String;

    -- True once a measurement was printed without an end of line
    Line_Left_Open : Boolean := False;

    -- True when the whole screen was asked for (-i) on a terminal
    Screen_Asked : Boolean := False;

    -- Messages of a run on the whole screen, held from its first cycle (a file that can't be written fails then, before the first frame) and printed when it closes; the latest is shown at the bottom of the screen
    Held : Unbounded_String;
    Last_Message : Unbounded_String;

    -- The colours of the logo, among the 256 every modern terminal has
    Bold : constant String := "1";
    Blue : constant String := "1;38;5;33";
    Flame : constant String := "1;38;5;202";
    Globe : constant String := "1;38;5;37";

    -- Faint, in the terminal's own text colour
    Dim : constant String := "2";

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

    function Colour (Text : in String; Code : in String) return String is
        (if Escapes and then Colours then ESC & "[" & Code & "m" & Text & ESC & "[0m" else Text);

    --------------------------------------------------

    function Banner return String is
        (Colour ("P", Blue) & Colour ("o", Flame) & Colour ("wer", Blue)
         & Colour ("J", Bold) & Colour ("o", Flame) & Colour ("ular", Bold)
         & " " & Colour (Version, Dim));

    --------------------------------------------------

    procedure Start (Config : in Options.Settings) is
        App : constant String := To_String (Config.App);
    begin
        if not Escapes then
            return;
        end if;

        Unicode := Platform.Enable_Unicode_Output;
        Screen_Asked := Config.Show_Screen;
        Name :=
            To_Unbounded_String
                (case Config.Target is
                    when Whole_System => "",
                    when One_Process => "PID" & CPU_Load.Process_ID'Image (Config.PID),
                    when One_Application => Head (App, Natural'Min (App'Length, App_Name_Width)));

        Put_Line (Banner);
        Flush;
    end Start;

    --------------------------------------------------

    -- Text padded on the left to Width, so the numbers stay in place from one second to the next
    function Align (Text : in String; Width : in Natural) return String is
        ((if Text'Length < Width then (Width - Text'Length) * ' ' else "") & Text);

    -- Value padded on the left to Width, or "n/a" if unreadable
    -- Scale multiplies the value, to print a load from 0.0 to 1.0 as a percentage
    function Number (Value : in Long_Float; Width : in Natural; Places : in Natural; Scale : in Long_Float := 1.0)
        return String is
        (Align ((if Is_Unreadable (Value) then "n/a" else Image (Scale * Value, Places)), Width));

    -- Power such as " 12.50 W"
    function Watts (Value : in Long_Float) return String is (Number (Value, 6, Decimals) & " W");

    -- A character of Unicode (blocks, box drawing) in UTF-8
    function U (Code : in Natural) return String is
        (Ada.Strings.UTF_Encoding.Wide_Strings.Encode ((1 => Wide_Character'Val (Code))));

    -- Ten cells for a fraction from 0.0 to 1.0, in blocks when the terminal shows UTF-8, in ASCII otherwise
    function Meter (Fraction : in Long_Float; Code : in String) return String is
        Full_Block : constant String := U (16#2588#);
        Light_Shade : constant String := U (16#2591#);

        Filled : constant Natural := Natural (10.0 * Long_Float'Min (1.0, Long_Float'Max (0.0, Fraction)));
    begin
        if Unicode then
            return Colour (Filled * Full_Block, Code) & Colour ((10 - Filled) * Light_Shade, Dim);
        else
            return Colour ("[", Dim) & Colour (Filled * '#', Code) & Colour ((10 - Filled) * '-' & "]", Dim);
        end if;
    end Meter;

    -- A fraction from 0.0 to 1.0 as a whole percentage padded to Width, such as " 58 %"
    function Percent (Fraction : in Long_Float; Width : in Natural) return String is
        (Align (Trim (Natural'Image (Natural (100.0 * Long_Float'Max (0.0, Fraction))), Ada.Strings.Left), Width) & " %");

    -- Power that follows "of", padded on the right so it sits next to the word, such as "12.50 W" (100 W and more take a column)
    function Watts_After (Value : in Long_Float) return String is
        (Image (Value, Decimals) & " W" & (if Value < 10.0 then " " else ""));

    --------------------------------------------------

    -- Write to the standard output directly, for the live line and the whole screen
    -- Text_IO counts the columns of a line, and neither ever ends one, so its count would wrap after a few months
    -- A write the terminal refuses for a moment (one another program left non-blocking, when it is full) is tried again; refused for a second in a row, the terminal is gone
    procedure Send (Text : in String) is
        Sent : Natural := 0;
        Written : Integer;
        Refused : Natural := 0;
    begin
        -- What Text_IO still holds goes first
        Flush;

        while Sent < Text'Length loop
            Written := GNAT.OS_Lib.Write (GNAT.OS_Lib.Standout, Text (Text'First + Sent)'Address, Text'Length - Sent);

            if Written > 0 then
                Sent := Sent + Written;
                Refused := 0;
            elsif Refused < 100 then
                Refused := Refused + 1;
                delay 0.01;
            else
                raise Ada.IO_Exceptions.Device_Error;
            end if;
        end loop;
    end Send;

    --------------------------------------------------

    -- The process's share of the CPU power, 0 when it can't be read or the CPU draws nothing
    function Share_Of (Data : in Cycle) return Long_Float is
        (if Is_Unreadable (Data.Target_Power) or else Data.CPU_Power <= 0.0 then 0.0
         else Data.Target_Power / Data.CPU_Power);

    -- One line of at most 72 columns, the CPU load metered for the whole system, the share of the CPU power for a process
    function Live_Line (Data : in Cycle; Target : in Target_Kind; GPU_Available : in Boolean) return String is
        Separator : constant String := Colour (" | ", Dim);
        Share : constant Long_Float := Share_Of (Data);
    begin
        case Target is
            when Whole_System =>
                return Colour ("Total ", Dim) & Colour (Watts (Data.Total_Power), Bold)
                       & Separator & Colour ("CPU ", Blue) & Watts (Data.CPU_Power)
                       & (if GPU_Available then Separator & Colour ("GPU ", Globe) & Watts (Data.GPU_Power) else "")
                       & Separator & Colour ("load ", Dim) & Meter (Data.CPU_Usage, Blue) & Percent (Data.CPU_Usage, 4);

            when One_Process | One_Application =>
                -- The process, then "of" the whole machine: its CPU power of the CPU power, its CPU usage of the CPU load
                return Colour (To_String (Name), Flame) & Separator & Colour ("CPU ", Blue) & Meter (Share, Flame)
                       & (if Is_Unreadable (Data.Target_Power) then Align ("n/a", 5) else Percent (Share, 3))
                       & Separator & Colour (Number (Data.Target_Power, 5, Decimals), Bold) & Colour (" of ", Dim)
                       & Watts_After (Data.CPU_Power)
                       & Separator & Colour ("usage", Dim) & Number (Data.Target_Usage, 5, 1, Scale => 100.0)
                       & Colour (" of ", Dim) & Percent (Data.CPU_Usage, 0);
        end case;
    end Live_Line;

    --------------------------------------------------

    -- The whole screen of -i, in powerjoular-terminal-screen.adb
    package Screen is

        -- Draw one cycle on the whole terminal, opening the screen on the first call
        procedure Draw (Data : in Cycle; Config : in Options.Settings; CPU_Available, GPU_Available : in Boolean);

        -- If it was opened, clear the screen and give the terminal its normal screen back
        procedure Close;

    end Screen;

    package body Screen is separate;

    --------------------------------------------------

    procedure Show (Data : in Cycle; Config : in Options.Settings; CPU_Available, GPU_Available : in Boolean) is
        Target : Target_Kind renames Config.Target;
    begin
        if Screen_Asked then
            Screen.Draw (Data, Config, CPU_Available, GPU_Available);
            return;
        elsif Escapes then
            -- Written over the previous line
            Send (Clear_Line & No_Wrap & Live_Line (Data, Target, GPU_Available) & Wrap);
            Line_Left_Open := True;
            return;
        end if;

        -- A file or a pipe keeps the text scripts may already read
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

        New_Line;

        -- A pipe or a file is block buffered, so flush every reading
        Flush;
    exception
        -- The reader of the pipe is gone: stop, as the SIGPIPE of POSIX does (Windows has none)
        when Ada.IO_Exceptions.Device_Error =>
            PowerJoular.Stop.Ask;
    end Show;

    --------------------------------------------------

    procedure Close_Line is
    begin
        if Line_Left_Open then
            New_Line;
            Line_Left_Open := False;
        end if;
    end Close_Line;

    -- Text after the name of the program, then Detail on its own line if any
    -- Written with Put_Line: Text_IO counts the columns of a line it did not end, and ends it once more on exit
    function Message (Text : in String; Detail : in String) return String is
        ("powerjoular: " & Text & (if Detail = "" then "" else LF & Detail));

    procedure Report (Text : in String; Detail : in String := "") is
    begin
        if Screen_Asked then
            if Length (Held) > 0 then
                Append (Held, LF);
            end if;

            Append (Held, Message (Text, Detail));
            Last_Message := To_Unbounded_String (Text);
        else
            Close_Line;
            Put_Line (Standard_Error, Message (Text, Detail));
        end if;
    end Report;

    --------------------------------------------------

    procedure Stop is
    begin
        Screen.Close;
        Close_Line;

        if Length (Held) > 0 then
            Put_Line (Standard_Error, To_String (Held));
            Held := Null_Unbounded_String;
        end if;

        Platform.Restore_Terminal;
    end Stop;

end PowerJoular.Terminal;
