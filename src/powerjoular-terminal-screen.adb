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

with Ada.Calendar.Formatting;
with GNAT.Calendar.Time_IO;

with Joular_Core;

with PowerJoular.CSV;
with PowerJoular.Ring_Buffer;

-- The whole screen of -i: the power in large digits, a side panel, bars and a chart, drawn whole at every cycle
-- A frame is built in a grid of cells, then sent at once, each row placed by its position and with no line end, so nothing scrolls
separate (PowerJoular.Terminal)
package body Screen is

    use type Ada.Calendar.Time;

    -- A bigger window keeps the frame in its top left corner
    Max_Columns : constant := 300;
    Max_Rows : constant := 100;

    -- Smaller than this, the window shows the line of -t; this big, the full layout, otherwise the compact one
    Small_Columns : constant := 50;
    Small_Rows : constant := 16;
    Full_Columns : constant := 80;
    Full_Rows : constant := 24;

    -- The load, readable on dark and light terminals
    Violet : constant String := "1;38;5;99";

    type Paint is (Plain, In_Bold, In_Dim, In_Blue, In_Flame, In_Globe, In_Violet, In_Reverse);

    -- One cell of the frame: a character in 1 to 4 bytes of UTF-8, and its paint
    -- Back colours the rest of a cell where one part of a bar ends and the next one starts
    type Cell is
        record
            Text : String (1 .. 4);
            Last : Positive range 1 .. 4;
            Ink : Paint;
            Back : Paint;
        end record;

    -- Cell has no defaults, so the frame takes no memory until -i draws in it
    Blank : constant Cell := (Text => (others => ' '), Last => 1, Ink => Plain, Back => Plain);

    Frame : array (0 .. Max_Rows - 1, 0 .. Max_Columns - 1) of Cell;

    -- Size of the frame being drawn
    Columns : Positive := Full_Columns;
    Rows : Positive := Full_Rows;

    -- True from the first frame until Close
    Open : Boolean := False;

    -- Set at every frame: UTF-8 glyphs, but not on the Linux text console, whose font lacks most of them
    Fancy : Boolean := False;

    -- The cycles the chart shows, the oldest first
    History : array (1 .. Max_Columns) of Cycle;
    Cycles_Kept : Natural := 0;

    -- Integer digits of the reading: it grows when needed and never shrinks, so the layout stays still
    Widest : Positive := 2;

    -- Lit half cells of the large digits: half rows 0 to 9 cover rows 2 to 6 of the frame
    Pixels : array (0 .. 9, 0 .. Max_Columns - 1) of Boolean;

    Unix_Epoch : constant Ada.Calendar.Time := Ada.Calendar.Formatting.Time_Of (1970, 1, 1, 0.0, Time_Zone => 0);

    --------------------------------------------------

    -- Eighths of a cell, filled from the bottom (U+2581 to U+2588) or from the left (U+258F to U+2588)
    function Lower_Eighths (Eighths : in Positive) return String is (U (16#2580# + Eighths));
    function Left_Eighths (Eighths : in Positive) return String is (U (16#2590# - Eighths));

    -- Shades and ASCII have no eighths
    function Whole_Cells return Boolean is (not Fancy or else not Colours);

    -- The first and the second part of a bar or of the chart; without colours the second is shaded
    function Fill (Part : in Positive) return String is
        (if not Fancy then (if Part = 1 then "#" else "=")
         elsif Part = 1 or else Colours then U (16#2588#)
         else U (16#2593#));

    function Empty_Cell return String is (if Fancy then U (16#2591#) else "-");

    -- The square of the legend, or the fill itself when no colour tells the parts apart
    function Marker (Part : in Positive) return String is
        (if Fancy and then Colours then U (16#25A0#) else Fill (Part));

    function Ellipsis return String is (if Fancy then U (16#2026#) else "...");

    --------------------------------------------------

    -- In UTF-8, the bytes 16#80# to 16#BF# continue the character before them
    function Continues (C : in Character) return Boolean is (Character'Pos (C) in 16#80# .. 16#BF#);

    -- Columns Text takes, one per character
    function Width (Text : in String) return Natural is
        Result : Natural := 0;
    begin
        for C of Text loop
            if not Continues (C) then
                Result := Result + 1;
            end if;
        end loop;

        return Result;
    end Width;

    -- Where the character at Position (from 1) starts in Text, or just past its end
    function Start_Of (Text : in String; Position : in Positive) return Positive is
        Seen : Natural := 0;
    begin
        for I in Text'Range loop
            if not Continues (Text (I)) then
                Seen := Seen + 1;

                if Seen = Position then
                    return I;
                end if;
            end if;
        end loop;

        return Text'Last + 1;
    end Start_Of;

    -- The first, or the last, Characters characters of Text
    function Head_Of (Text : in String; Characters : in Natural) return String is
        (Text (Text'First .. Start_Of (Text, Characters + 1) - 1));

    function Tail_Of (Text : in String; Characters : in Natural) return String is
        (Text (Start_Of (Text, Positive'Max (1, Width (Text) - Characters + 1)) .. Text'Last));

    -- Text cut to Room columns, its end replaced by an ellipsis
    function Cut_Right (Text : in String; Room : in Natural) return String is
        (if Width (Text) <= Room then Text
         elsif Room <= Width (Ellipsis) then Head_Of (Text, Room)
         else Head_Of (Text, Room - Width (Ellipsis)) & Ellipsis);

    -- The same, cutting the start, so a path keeps its file name
    function Cut_Left (Text : in String; Room : in Natural) return String is
        (if Width (Text) <= Room then Text
         elsif Room <= Width (Ellipsis) then Tail_Of (Text, Room)
         else Ellipsis & Tail_Of (Text, Room - Width (Ellipsis)));

    --------------------------------------------------

    -- A cell outside the frame is never written
    procedure Set (Column, Row : in Integer; Glyph : in String; Ink : in Paint; Back : in Paint := Plain) is
    begin
        if Column in 0 .. Columns - 1 and then Row in 0 .. Rows - 1 then
            Frame (Row, Column) :=
                (Text => Glyph & (1 .. 4 - Glyph'Length => ' '),
                 Last => Glyph'Length,
                 Ink => (if Colours then Ink else Plain),
                 Back => (if Colours then Back else Plain));
        end if;
    end Set;

    -- Put Text from Column on Row, one character per cell, and move Column past it
    -- A control character would move the cursor, so it shows as '?'
    procedure Place (Column : in out Integer; Row : in Integer; Text : in String; Ink : in Paint := Plain) is
    begin
        for C of Text loop
            if not Continues (C) then
                Set (Column, Row, (if C < ' ' or else C = Character'Val (127) then "?" else (1 => C)), Ink);
                Column := Column + 1;
            elsif Column - 1 in 0 .. Columns - 1 and then Row in 0 .. Rows - 1 then
                declare
                    Previous : Cell renames Frame (Row, Column - 1);
                begin
                    if Previous.Last < 4 then
                        Previous.Last := Previous.Last + 1;
                        Previous.Text (Previous.Last) := C;
                    end if;
                end;
            end if;
        end loop;
    end Place;

    procedure Place_At (Column, Row : in Integer; Text : in String; Ink : in Paint := Plain) is
        At_Column : Integer := Column;
    begin
        Place (At_Column, Row, Text, Ink);
    end Place_At;

    -- Text ending at Last_Column
    procedure Place_Right (Last_Column, Row : in Integer; Text : in String; Ink : in Paint := Plain) is
    begin
        Place_At (Last_Column - Width (Text) + 1, Row, Text, Ink);
    end Place_Right;

    --------------------------------------------------

    -- Move to the start of a row, counted from 1 as terminals do
    function Row_Start (Row : in Positive) return String is
        (ESC & "[" & Trim (Positive'Image (Row), Ada.Strings.Left) & ";1H");

    -- Send a frame, the first one behind the switch to the alternate screen, with the cursor hidden
    -- The cursor then waits at the top left, so a key the terminal echoes never scrolls the screen
    procedure Send_Screen (Text : in String) is
        Opening : constant String := (if Open then "" else ESC & "[?1049h" & ESC & "[?25l");
    begin
        -- Before sending, so Close closes it even if the sending fails half way
        Open := True;
        Send (Opening & No_Wrap & Text & Row_Start (1) & Wrap);
    end Send_Screen;

    --------------------------------------------------

    function Code (Ink : in Paint) return String is
        (case Ink is
            when Plain => "",
            when In_Bold => Bold,
            when In_Dim => Dim,
            when In_Blue => Blue,
            when In_Flame => Flame,
            when In_Globe => Globe,
            when In_Violet => Violet,
            when In_Reverse => "7");

    -- The same colour as a background, in a cell shared by two parts of a bar
    function Background (Back : in Paint) return String is
        (case Back is
            when In_Blue => ";48;5;33",
            when In_Flame => ";48;5;202",
            when In_Globe => ";48;5;37",
            when In_Violet => ";48;5;99",
            when others => "");

    -- Every cell, the escape codes written only where the paint changes
    procedure Send_Frame is
        Output : Unbounded_String;
        Ink : Paint := Plain;
        Back : Paint := Plain;
    begin
        for Row in 0 .. Rows - 1 loop
            Append (Output, Row_Start (Row + 1));

            for Column in 0 .. Columns - 1 loop
                -- Never the last cell: a terminal that ignores No_Wrap would scroll there
                exit when Row = Rows - 1 and then Column = Columns - 1;

                declare
                    This : Cell renames Frame (Row, Column);
                begin
                    -- Reset, then the new paint, in one sequence
                    if This.Ink /= Ink or else This.Back /= Back then
                        Ink := This.Ink;
                        Back := This.Back;
                        Append (Output, ESC & "[0" & (if Ink = Plain then "" else ";" & Code (Ink) & Background (Back)) & "m");
                    end if;

                    Append (Output, This.Text (1 .. This.Last));
                end;
            end loop;
        end loop;

        if Ink /= Plain then
            Append (Output, ESC & "[0m");
        end if;

        -- Clear that last cell, which may still hold a wider frame
        Append (Output, ESC & "[K");

        Send_Screen (To_String (Output));
    end Send_Frame;

    -- A window too small for the screen: the line of -t, and the size it needs
    procedure Send_Small (Data : in Cycle; Target : in Target_Kind; GPU_Available : in Boolean) is
        -- Each row is cleared before its text: cleared after, a line cut at the edge would lose its last character
        Hint : constant String :=
            (if Rows < 4 then ""
             else Row_Start (3) & Clear_Line
                  & Colour ("Enlarge the window to" & Natural'Image (Small_Columns) & " by" & Natural'Image (Small_Rows), Dim)
                  & Row_Start (4) & Clear_Line & Colour ("for the full view.", Dim));
    begin
        Send_Screen (Row_Start (1) & Clear_Line & Live_Line (Data, Target, GPU_Available)
                     & (if Rows < 2 then "" else Row_Start (2) & Clear_Line)
                     & Hint & ESC & "[J");
    end Send_Small;

    --------------------------------------------------

    -- Strokes a to g of each digit, as on a seven-segment display
    Segments : constant array (Character range '0' .. '9') of String (1 .. 7) :=
        ("1111110", "0110000", "1101101", "1111001", "0110011", "1011011", "1011111", "1110000", "1111111", "1111011");

    -- The digits in ASCII: 3 by 5 pixels, each of two characters
    type Glyph_Rows is array (0 .. 4) of String (1 .. 3);

    Small_Font : constant array (Character range '0' .. '9') of Glyph_Rows :=
        (("111", "101", "101", "101", "111"),
         ("110", "010", "010", "010", "111"),
         ("111", "001", "111", "100", "111"),
         ("111", "001", "111", "001", "111"),
         ("101", "101", "111", "001", "001"),
         ("111", "100", "111", "001", "111"),
         ("111", "100", "111", "101", "111"),
         ("111", "001", "001", "001", "001"),
         ("111", "101", "111", "101", "111"),
         ("111", "101", "111", "001", "111"));

    procedure Light (Column, Half_Row : in Integer) is
    begin
        if Column in 0 .. Max_Columns - 1 then
            Pixels (Half_Row, Column) := True;
        end if;
    end Light;

    -- The columns and half rows of a stroke, from the top left of its digit (6 columns by 9 half rows)
    type Area is
        record
            First_Column, Last_Column, First_Half_Row, Last_Half_Row : Natural;
        end record;

    -- a (top), b (top right), c (bottom right), d (bottom), e (bottom left), f (top left), g (middle)
    -- Strokes run into the corners, so a digit is drawn in continuous lines rather than in segments with gaps
    Strokes : constant array (1 .. 7) of Area :=
        ((0, 5, 0, 0), (5, 5, 0, 4), (5, 5, 4, 8), (0, 5, 8, 8), (0, 0, 4, 8), (0, 0, 0, 4), (0, 5, 4, 4));

    procedure Light_Stroke (Column : in Integer; Stroke : in Positive) is
        This : Area renames Strokes (Stroke);
    begin
        for X in This.First_Column .. This.Last_Column loop
            for Y in This.First_Half_Row .. This.Last_Half_Row loop
                Light (Column + X, Y);
            end loop;
        end loop;
    end Light_Stroke;

    -- A digit, or a dash, from Column on rows 2 to 6
    procedure Draw_Digit (Column : in Integer; Digit : in Character; Ink : in Paint) is
    begin
        if Fancy and then Digit = '-' then
            Light_Stroke (Column, 7);
        elsif Fancy then
            for Stroke in 1 .. 7 loop
                if Segments (Digit) (Stroke) = '1' then
                    Light_Stroke (Column, Stroke);
                end if;
            end loop;
        elsif Digit = '-' then
            Place_At (Column, 4, "######", Ink);
        else
            for Row in 0 .. 4 loop
                for Pixel in 1 .. 3 loop
                    if Small_Font (Digit) (Row) (Pixel) = '1' then
                        Place_At (Column + 2 * (Pixel - 1), 2 + Row, "##", Ink);
                    end if;
                end loop;
            end loop;
        end if;
    end Draw_Digit;

    -- Text in large digits from Column on rows 2 to 6, and the column of the unit, 2 columns after the last digit
    -- Digits are 6 columns wide and 2 apart, the point 1 column in a slot of 2 (3 and 7 in ASCII)
    procedure Draw_Number (Column : in Integer; Text : in String; Ink : in Paint; Unit_Column : out Integer) is
        X : Integer := Column;
        Last_Digit : Integer := Column;
    begin
        Pixels := (others => (others => False));

        for C of Text loop
            if C = '.' and then Fancy then
                Light (X, 8);
                X := X + 2;
            elsif C = '.' then
                Place_At (X, 6, "##", Ink);
                X := X + 3;
            else
                -- A blank keeps the place of a digit
                if C in '0' .. '9' | '-' then
                    Draw_Digit (X, C, Ink);
                    Last_Digit := X;
                end if;

                X := X + (if Fancy then 8 else 7);
            end if;
        end loop;

        -- Two half cells per cell
        if Fancy then
            for Row in 0 .. 4 loop
                for Col in 0 .. Columns - 1 loop
                    declare
                        Top_Half : constant Boolean := Pixels (2 * Row, Col);
                        Bottom_Half : constant Boolean := Pixels (2 * Row + 1, Col);
                    begin
                        if Top_Half and then Bottom_Half then
                            Set (Col, 2 + Row, U (16#2588#), Ink);
                        elsif Top_Half then
                            Set (Col, 2 + Row, U (16#2580#), Ink);
                        elsif Bottom_Half then
                            Set (Col, 2 + Row, U (16#2584#), Ink);
                        end if;
                    end;
                end loop;
            end loop;
        end if;

        Unit_Column := Last_Digit + 8;
    end Draw_Number;

    --------------------------------------------------

    -- Fraction of Cells cells, in eighths of a cell, rounded to an eighth, or to a whole cell without eighths
    function Eighths (Fraction : in Long_Float; Cells : in Natural) return Natural is
        Steps : constant Positive := (if Whole_Cells then 1 else 8);
    begin
        return Natural (Long_Float'Min (1.0, Long_Float'Max (0.0, Fraction)) * Long_Float (Cells * Steps)) * (8 / Steps);
    end Eighths;

    -- A bar of Size cells from Column: First, then Second, as fractions of it, the rest empty
    -- Each part ends at its running total
    procedure Draw_Bar (Column, Row : in Integer; Size : in Natural;
                        First : in Long_Float; First_Ink : in Paint;
                        Second : in Long_Float := 0.0; Second_Ink : in Paint := Plain) is
        End_First : constant Natural := Eighths (First, Size);
        End_Second : constant Natural := Eighths (Long_Float'Max (0.0, First) + Long_Float'Max (0.0, Second), Size);
    begin
        for I in 0 .. Size - 1 loop
            declare
                In_First : constant Natural := Integer'Min (8, Integer'Max (0, End_First - 8 * I));
                In_Second : constant Natural := Integer'Min (8, Integer'Max (0, End_Second - 8 * I)) - In_First;
            begin
                if In_First = 8 then
                    Set (Column + I, Row, Fill (1), First_Ink);
                elsif In_First > 0 then
                    -- The second part, if it starts here, colours the rest of the cell
                    Set (Column + I, Row, Left_Eighths (In_First), First_Ink,
                         Back => (if In_Second > 0 then Second_Ink else Plain));
                elsif In_Second = 8 then
                    Set (Column + I, Row, Fill (2), Second_Ink);
                elsif In_Second > 0 then
                    Set (Column + I, Row, Left_Eighths (In_Second), Second_Ink);
                else
                    Set (Column + I, Row, Empty_Cell, In_Dim);
                end if;
            end;
        end loop;
    end Draw_Bar;

    -- One column of the chart, Height rows up from Bottom_Row: Upper high on a scale of Top, Lower of it in Lower_Ink
    procedure Draw_Column (Column, Bottom_Row, Height : in Integer;
                           Lower, Upper, Top : in Long_Float;
                           Lower_Ink, Upper_Ink : in Paint) is
        Lower_Top : constant Natural := Eighths (Lower / Top, Height);
        Upper_Top : constant Natural := Natural'Max (Lower_Top, Eighths (Upper / Top, Height));
    begin
        for Row in 0 .. Height - 1 loop
            declare
                Filled : constant Integer := Integer'Min (8, Upper_Top - 8 * Row);

                -- A cell crossed by both parts takes the colour of the one that covers its middle,
                -- and a cell of the lower part alone keeps its colour
                Part : constant Positive := (if Lower_Top >= Integer'Min (Upper_Top, 8 * Row + 4) then 1 else 2);
            begin
                exit when Filled <= 0;

                Set (Column, Bottom_Row - Row,
                     (if Whole_Cells then Fill (Part) else Lower_Eighths (Filled)),
                     (if Part = 1 then Lower_Ink else Upper_Ink));
            end;
        end loop;
    end Draw_Column;

    procedure Draw_Box (Left, Top, Right, Bottom : in Integer) is
        Across : constant String := (if Fancy then U (16#2500#) else "-");
        Down : constant String := (if Fancy then U (16#2502#) else "|");
    begin
        for Column in Left + 1 .. Right - 1 loop
            Set (Column, Top, Across, In_Dim);
            Set (Column, Bottom, Across, In_Dim);
        end loop;

        for Row in Top + 1 .. Bottom - 1 loop
            Set (Left, Row, Down, In_Dim);
            Set (Right, Row, Down, In_Dim);
        end loop;

        Set (Left, Top, (if Fancy then U (16#256D#) else "+"), In_Dim);
        Set (Right, Top, (if Fancy then U (16#256E#) else "+"), In_Dim);
        Set (Left, Bottom, (if Fancy then U (16#2570#) else "+"), In_Dim);
        Set (Right, Bottom, (if Fancy then U (16#256F#) else "+"), In_Dim);
    end Draw_Box;

    --------------------------------------------------

    -- The time of a measurement, HH:MM:SS in local time
    function Local_Time (Unix_Time : in Long_Long_Integer) return String is
    begin
        return GNAT.Calendar.Time_IO.Image (Unix_Epoch + Duration (Unix_Time), "%H:%M:%S");
    exception
        -- A clock out of the years Ada.Calendar holds
        when others =>
            return "";
    end Local_Time;

    -- The top of the chart: 5, 10, or the next ten watts above Highest
    function Scale_Top (Highest : in Long_Float) return Long_Float is
        (if Highest <= 5.0 then 5.0
         elsif Highest <= 10.0 then 10.0
         else 10.0 * Long_Float'Ceiling (Long_Float'Min (Highest, 1.0E9) / 10.0));

    function Scale_Image (Top : in Long_Float) return String is
        (Trim (Long_Long_Integer'Image (Long_Long_Integer (Top)), Ada.Strings.Left) & " W");

    -- Keep the cycle for the chart, dropping the oldest when the history is full
    procedure Remember (Data : in Cycle) is
    begin
        if Cycles_Kept = History'Last then
            History (1 .. History'Last - 1) := History (2 .. History'Last);
        else
            Cycles_Kept := Cycles_Kept + 1;
        end if;

        History (Cycles_Kept) := Data;
    end Remember;

    --------------------------------------------------

    -- The frame of one cycle, full from 80 by 24, compact below
    procedure Build (Data : in Cycle; Config : in Options.Settings; CPU_Available, GPU_Available : in Boolean) is
        Full : constant Boolean := Columns >= Full_Columns and then Rows >= Full_Rows;
        Process : constant Boolean := Config.Target /= Whole_System;

        Target_Name : constant String :=
            (case Config.Target is
                when Whole_System => "whole system",
                when One_Process => "PID" & CPU_Load.Process_ID'Image (Config.PID),
                when One_Application => To_String (Config.App));

        -- After the figures of the process, at the right of the bars
        Tag : constant String := (if Config.Target = One_Application then "app" else "PID");

        Unreadable : constant Boolean := Process and then Is_Unreadable (Data.Target_Power);
        Share : constant Long_Float := Share_Of (Data);

        Reading_Column : constant Integer := (if Full then 3 else 2);

        -- Bars: label, value ending at Value_End, the bar, then a value ending at Right_End and its label
        Value_End : constant Integer := (if Full then 15 else 13);
        Bar_Column : constant Integer := (if Full then 18 else 15);
        Bar_Size : constant Integer := (if Full then Columns - 36 else Columns - 29);
        Right_End : constant Integer := (if Full then Columns - 7 else Columns - 6);
        Right_Label : constant Integer := Right_End + 2;

        Unit_Column : Integer;
        Row : Integer;
    begin
        for R in 0 .. Rows - 1 loop
            for C in 0 .. Columns - 1 loop
                Frame (R, C) := Blank;
            end loop;
        end loop;

        -- Header: the name, what is monitored, the time of the measurement
        declare
            Column : Integer := 1;
            Time_Text : constant String := Local_Time (Data.Time);
        begin
            Place (Column, 0, "P", In_Blue);
            Place (Column, 0, "o", In_Flame);
            Place (Column, 0, "wer", In_Blue);
            Place (Column, 0, "J", In_Bold);
            Place (Column, 0, "o", In_Flame);
            Place (Column, 0, "ular", In_Bold);
            Place (Column, 0, " " & Version, In_Dim);
            Column := Column + 3;
            Place (Column, 0, Cut_Right (Target_Name, Integer'Max (0, Columns - Column - Time_Text'Length - 3)),
                   (if Process then In_Flame else Plain));
            Place_Right (Columns - 2, 0, Time_Text, In_Bold);
        end;

        -- The reading: the machine's total, or the process's power
        declare
            Value_Text : constant String :=
                (if Unreadable then "" else Image ((if Process then Data.Target_Power else Data.Total_Power), Decimals));
            Point : constant Natural := Index (Value_Text, ".");
            Integer_Digits : constant Natural := (if Point = 0 then Value_Text'Length else Point - Value_Text'First);
        begin
            Widest := Positive'Max (Widest, Integer_Digits);

            Draw_Number (Reading_Column,
                         (if Unreadable then Widest * '-' & ".--" else (Widest - Integer_Digits) * ' ' & Value_Text),
                         (if Process then In_Flame else Plain),
                         Unit_Column);
            Place_At (Unit_Column, 6, "W", (if Process then In_Flame else In_Bold));
        end;

        -- The side panel, what -d prints and what the options write, and the caption under the reading
        -- The panel moves right when the reading grows, and is left out with fewer than 11 columns for its values
        -- Its values start 5 columns after the labels, 4 in the compact layout, so "not available" fits a Raspberry Pi's window
        declare
            Panel_Column : constant Integer := Integer'Max ((if Full then Columns - 34 else Columns - 24), Unit_Column + 5);
            Value_Column : constant Integer := Panel_Column + (if Full then 5 else 4);
            Room : constant Integer := Columns - 2 - Value_Column;
            Panel_Shown : constant Boolean := Room >= 11;
            Last_Row : constant Integer := (if Full then 7 else 6);
            Panel_Row : Integer := 2;

            File : constant String := To_String (Config.CSV_File);
            Latest : constant String := ", latest only";
            VM_File : constant String := To_String (Config.VM_File);
            Read_From : constant String := "read from ";

            -- One row of the panel, a word cut on the right; a file comes cut on the left already, so it keeps its name
            procedure Line (Label : in String; Label_Ink : in Paint; Value : in String; Value_Ink : in Paint) is
            begin
                if Panel_Row <= Last_Row then
                    Place_At (Panel_Column, Panel_Row, Label, Label_Ink);
                    Place_At (Value_Column, Panel_Row, Cut_Right (Value, Room), Value_Ink);
                    Set (Panel_Column - 3, Panel_Row, (if Fancy then U (16#2502#) else "|"), In_Dim);
                    Panel_Row := Panel_Row + 1;
                end if;
            end Line;

            Column : Integer := Reading_Column;
            Tail : constant String :=
                (if Unreadable then ": n/a, stopped or not readable" else ", its share of the CPU power");

            -- The caption ends 2 columns before the panel's line, which reaches its row in the full layout only
            Caption_End : constant Integer := (if Panel_Shown and then Full then Panel_Column - 5 else Columns - 2);
        begin
            if Process then
                Place (Column, 7, Cut_Right (Target_Name, Integer'Max (3, Caption_End - Column + 1 - Tail'Length)),
                       In_Flame);
                Place (Column, 7, Tail, In_Dim);
            else
                Place (Column, 7, (if GPU_Available then "total, CPU + GPU" else "total, CPU only"), In_Dim);
            end if;

            if Panel_Shown then
                if Config.Read_VM then
                    -- "read from " is left out when it would leave the file fewer than 8 columns
                    Line ("CPU", In_Blue,
                          (if Room - Read_From'Length >= 8 then Read_From & Cut_Left (VM_File, Room - Read_From'Length)
                           else Cut_Left (VM_File, Room)),
                          Plain);
                else
                    Line ("CPU", In_Blue, (if CPU_Available then "available" else "not available"),
                          (if CPU_Available then Plain else In_Dim));
                end if;

                Line ("GPU", In_Globe, (if GPU_Available then "available" else "not available"),
                      (if GPU_Available then Plain else In_Dim));

                if Config.Write_CSV then
                    Line ((if Config.Overwrite then "-o" else "-f"), In_Dim,
                          Cut_Left ((if Config.Overwrite and then Width (File & Latest) <= Room then File & Latest else File),
                                    Room),
                          Plain);

                    if Process then
                        Line ("", Plain, Cut_Left (CSV.Target_Name, Room), Plain);
                    end if;
                end if;

                -- As -d, no row for a ring buffer that failed to open
                if Config.Write_Ring_Buffer then
                    Line ("-r", In_Dim, Cut_Left (Ring_Buffer.Path, Room), Plain);
                elsif not Config.Write_CSV then
                    Line ("", Plain, "nothing saved", In_Dim);
                end if;

                if Config.Show_Debug then
                    Line ("-d", In_Dim, "Joular Core " & Joular_Core.Version, In_Dim);
                    Line ("", Plain, "CPU Load " & CPU_Load.Version, In_Dim);
                end if;
            end if;
        end;

        -- Bars: CPU and GPU, or the process's share of the CPU power, then the CPU load
        Row := (if Full then 9 else 8);

        if Process then
            Place_At (Reading_Column, Row, "CPU", In_Blue);
            Place_Right (Value_End, Row, Watts (Data.CPU_Power));

            if Unreadable or else Data.CPU_Power <= 0.0 then
                Draw_Bar (Bar_Column, Row, Bar_Size, 0.0, Plain);
            else
                Draw_Bar (Bar_Column, Row, Bar_Size, Share, In_Flame, 1.0 - Share, In_Blue);
            end if;

            Place_Right (Right_End, Row, (if Unreadable then "n/a" else Percent (Share, 0)));
            Place_At (Right_Label, Row, Tag, In_Flame);
            Row := Row + (if Full then 2 else 1);
        elsif GPU_Available then
            Place_At (Reading_Column, Row, "CPU", In_Blue);
            Place_Right (Value_End, Row, Watts (Data.CPU_Power));

            if Data.Total_Power > 0.0 then
                Draw_Bar (Bar_Column, Row, Bar_Size,
                          Data.CPU_Power / Data.Total_Power, In_Blue, Data.GPU_Power / Data.Total_Power, In_Globe);
            else
                Draw_Bar (Bar_Column, Row, Bar_Size, 0.0, Plain);
            end if;

            Place_Right (Right_End, Row, Watts (Data.GPU_Power));
            Place_At (Right_Label, Row, "GPU", In_Globe);
            Row := Row + (if Full then 2 else 1);
        end if;

        Place_At (Reading_Column, Row, "Load", In_Violet);
        Place_Right (Value_End, Row, Percent (Data.CPU_Usage, 0));

        if Process and then not Is_Unreadable (Data.Target_Usage) then
            Draw_Bar (Bar_Column, Row, Bar_Size,
                      Data.Target_Usage, In_Flame, Data.CPU_Usage - Data.Target_Usage, In_Violet);
        else
            Draw_Bar (Bar_Column, Row, Bar_Size, Data.CPU_Usage, In_Violet);
        end if;

        if Process then
            Place_Right (Right_End, Row,
                         (if Is_Unreadable (Data.Target_Usage) then "n/a" else Image (100.0 * Data.Target_Usage, 1) & " %"));
            Place_At (Right_Label, Row, Tag, In_Flame);
        end if;

        -- Chart: one column per cycle, the newest at the right
        declare
            Top_Row : constant Integer := Row + 1;
            Plot_Column : constant Integer := (if Full then 9 else 2);
            Plot_Size : constant Integer := Columns - 2 - Plot_Column;
            Plot_Bottom : constant Integer := (if Full then Rows - 4 else Rows - 3);
            Height : constant Integer := Plot_Bottom - Top_Row;
            Shown : constant Natural := Natural'Min (Plot_Size, Cycles_Kept);
            First : constant Positive := Cycles_Kept - Shown + 1;
            Highest : Long_Float := 0.0;
            Top : Long_Float;
            Column : Integer := 3;

            -- The two parts of a column: the CPU under the GPU, or the process under the rest of the CPU
            Lower_Ink : constant Paint := (if Process then In_Flame else In_Blue);
            Upper_Ink : constant Paint := (if Process then In_Blue else In_Globe);

            function Lower_Of (Item : in Cycle) return Long_Float is
                (if not Process then (if GPU_Available then Item.CPU_Power else Item.Total_Power)
                 elsif Is_Unreadable (Item.Target_Power) then 0.0
                 else Item.Target_Power);

            function Upper_Of (Item : in Cycle) return Long_Float is
                (if Process then Item.CPU_Power else Item.Total_Power);
        begin
            for I in First .. Cycles_Kept loop
                Highest := Long_Float'Max (Highest, Upper_Of (History (I)));
            end loop;

            Top := Scale_Top (Highest);

            Draw_Box (1, Top_Row, Columns - 2, Rows - 2);
            Place (Column, Top_Row, " ");
            Place (Column, Top_Row, "Power", In_Bold);
            Place (Column, Top_Row, ", one bar a second ", In_Dim);

            for I in First .. Cycles_Kept loop
                Draw_Column (Plot_Column + Plot_Size - Shown + (I - First), Plot_Bottom, Height,
                             Lower_Of (History (I)), Upper_Of (History (I)), Top, Lower_Ink, Upper_Ink);
            end loop;

            if Full then
                -- Legend at the right of the top border, its squares filled as the parts are
                declare
                    First_Name : constant String := (if Process then Cut_Right (Target_Name, 12) else "CPU");
                    Second_Name : constant String := (if Process then "CPU" elsif GPU_Available then "GPU" else "");

                    -- Each entry: a space, its square, its name between spaces
                    Legend_Width : constant Natural :=
                        4 + Width (First_Name) + (if Second_Name = "" then 0 else 4 + Width (Second_Name));
                    Legend_Column : Integer := Columns - 3 - Legend_Width;
                begin
                    Place (Legend_Column, Top_Row, " ");
                    Place (Legend_Column, Top_Row, Marker (1), Lower_Ink);
                    Place (Legend_Column, Top_Row, " " & First_Name & " ", In_Dim);

                    if Second_Name /= "" then
                        Place (Legend_Column, Top_Row, " ");
                        Place (Legend_Column, Top_Row, Marker (2), Upper_Ink);
                        Place (Legend_Column, Top_Row, " " & Second_Name & " ", In_Dim);
                    end if;
                end;

                -- Wider than the margin (from 10000 W), the scale is left out rather than shown cut
                if Width (Scale_Image (Top)) <= 6 then
                    Place_Right (7, Top_Row + 1, Scale_Image (Top), In_Dim);
                end if;

                Place_Right (7, Plot_Bottom, "0 W", In_Dim);

                -- Every 30 cycles, counted back from now, centred under its column
                for Tick in 1 .. (Plot_Size - 3) / 30 loop
                    Place_At (Plot_Column + Plot_Size - 3 - 30 * Tick, Rows - 3, Integer'Image (-30 * Tick) & " s", In_Dim);
                end loop;

                Place_Right (Columns - 3, Rows - 3, "now", In_Dim);
            else
                -- The scale, where the legend would be
                Place_Right (Columns - 4, Top_Row, " " & Scale_Image (Top) & " ", In_Dim);
            end if;
        end;

        -- Footer: how to stop, and the latest message held
        declare
            Column : Integer := 1;
        begin
            Place (Column, Rows - 1, " Ctrl+C ", In_Reverse);
            Column := Column + 1;
            Place (Column, Rows - 1, "stop", In_Dim);
            Place_Right (Columns - 2, Rows - 1,
                         Cut_Right (To_String (Last_Message), Integer'Max (0, Columns - Column - 4)), In_Flame);
        end;
    end Build;

    --------------------------------------------------

    procedure Draw (Data : in Cycle; Config : in Options.Settings; CPU_Available, GPU_Available : in Boolean) is
        Window_Columns, Window_Rows : Positive;
    begin
        Platform.Terminal_Size (Window_Columns, Window_Rows);
        Columns := Positive'Min (Window_Columns, Max_Columns);
        Rows := Positive'Min (Window_Rows, Max_Rows);
        Fancy := Unicode and then Ada.Environment_Variables.Value ("TERM", "") /= "linux";

        Remember (Data);

        if Columns < Small_Columns or else Rows < Small_Rows then
            Send_Small (Data, Config.Target, GPU_Available);
        else
            Build (Data, Config, CPU_Available, GPU_Available);
            Send_Frame;
        end if;
    end Draw;

    --------------------------------------------------

    -- Clearing first also leaves a clean screen on a terminal with no alternate screen (the Linux console)
    -- Colours and wrapping are reset too, in case the last frame was cut half way
    procedure Close is
    begin
        if Open then
            -- First, so a second Shut_Down (after an error in the first) writes nothing twice
            Open := False;
            Send (ESC & "[0m" & ESC & "[2J" & ESC & "[H" & ESC & "[?25h" & Wrap & ESC & "[?1049l");
        end if;
    exception
        -- The terminal is gone (its window was closed): nothing left to give back
        when Ada.IO_Exceptions.Device_Error =>
            null;
    end Close;

end Screen;
