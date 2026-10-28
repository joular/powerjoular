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
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;

with CPU_Load;

with PowerJoular.Formatting; use PowerJoular.Formatting;
with PowerJoular.Platform;

package body PowerJoular.Terminal is

    Decimals : constant := 2;

    -- Go back to the start of the line and clear it
    Clear_Line : constant String := CR & ESC & "[0K";

    -- Turn the wrapping off while the live line is written, so a window narrower than it cuts it at the edge
    -- A wrapped line would leave its first part behind at every rewrite
    No_Wrap : constant String := ESC & "[?7l";
    Wrap : constant String := ESC & "[?7h";

    Escapes : Boolean := False;

    -- True when the terminal shows UTF-8, for the blocks of the meters
    Unicode : Boolean := False;

    -- PID or name of the application monitored, the name cut so the live line keeps within 72 columns
    App_Name_Width : constant := 9;
    Name : Unbounded_String;

    -- True once a measurement was printed without an end of line
    Line_Left_Open : Boolean := False;

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

    -- A NO_COLOR that is set and not empty asks for no colours (no-color.org)
    function Colour (Text : in String; Code : in String) return String is
        (if Escapes and then Ada.Environment_Variables.Value ("NO_COLOR", "") = ""
         then ESC & "[" & Code & "m" & Text & ESC & "[0m"
         else Text);

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

    -- Ten cells for a fraction from 0.0 to 1.0, in blocks when the terminal shows UTF-8, in ASCII otherwise
    function Meter (Fraction : in Long_Float; Code : in String) return String is
        Full_Block : constant String := Character'Val (16#E2#) & Character'Val (16#96#) & Character'Val (16#88#);
        Light_Shade : constant String := Character'Val (16#E2#) & Character'Val (16#96#) & Character'Val (16#91#);

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

    -- Power that follows "of", padded on the right so it sits next to the word, such as "12.50 W"
    function Watts_After (Value : in Long_Float) return String is (Head (Image (Value, Decimals) & " W", 7));

    --------------------------------------------------

    -- One line of at most 72 columns, the CPU load metered for the whole system, the share of the CPU power for a process
    procedure Show_Live (Data : in Cycle; Target : in Target_Kind; GPU_Available : in Boolean) is
        Separator : constant String := Colour (" | ", Dim);

        Share : constant Long_Float :=
            (if Is_Unreadable (Data.Target_Power) or else Data.CPU_Power <= 0.0 then 0.0
             else Data.Target_Power / Data.CPU_Power);
    begin
        Put (Clear_Line & No_Wrap);

        case Target is
            when Whole_System =>
                Put (Colour ("Total ", Dim) & Colour (Watts (Data.Total_Power), Bold));
                Put (Separator & Colour ("CPU ", Blue) & Watts (Data.CPU_Power));

                if GPU_Available then
                    Put (Separator & Colour ("GPU ", Globe) & Watts (Data.GPU_Power));
                end if;

                Put (Separator & Colour ("load ", Dim) & Meter (Data.CPU_Usage, Blue) & Percent (Data.CPU_Usage, 4));

            when One_Process | One_Application =>
                -- The process, then "of" the whole machine: its CPU power of the CPU power, its CPU usage of the CPU load
                Put (Colour (To_String (Name), Flame) & Separator & Colour ("CPU ", Blue) & Meter (Share, Flame));
                Put ((if Is_Unreadable (Data.Target_Power) then Align ("n/a", 5) else Percent (Share, 3)));
                Put (Separator & Colour (Number (Data.Target_Power, 5, Decimals), Bold) & Colour (" of ", Dim)
                     & Watts_After (Data.CPU_Power));
                Put (Separator & Colour ("usage", Dim) & Number (Data.Target_Usage, 5, 1, Scale => 100.0)
                     & Colour (" of ", Dim) & Percent (Data.CPU_Usage, 0));
        end case;

        Put (Wrap);
        Line_Left_Open := True;
        Flush;
    end Show_Live;

    --------------------------------------------------

    procedure Show (Data : in Cycle; Target : in Target_Kind; GPU_Available : in Boolean) is
    begin
        if Escapes then
            Show_Live (Data, Target, GPU_Available);
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
    end Show;

    --------------------------------------------------

    procedure Close_Line is
    begin
        if Line_Left_Open then
            New_Line;
            Line_Left_Open := False;
        end if;
    end Close_Line;

    procedure Stop is
    begin
        Close_Line;
        Platform.Restore_Terminal;
    end Stop;

end PowerJoular.Terminal;
