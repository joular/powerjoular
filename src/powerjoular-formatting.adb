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

with Ada.Calendar; use Ada.Calendar;
with Ada.Calendar.Conversions;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;
with Interfaces.C;

package body PowerJoular.Formatting is

    -- Ada writes floats in the exponent notation by default, this writes them in plain digits
    package Value_IO is new Ada.Text_IO.Float_IO (Long_Float);

    --------------------------------------------------

    function Image (Value : in Long_Float; Decimals : in Natural) return String is
        -- The number is written right aligned in here, then the spaces in front of it are cut off
        -- Wide enough for any power or load value, sign, dot and decimals included
        Buffer : String (1 .. 64);
    begin
        Value_IO.Put (To => Buffer, Item => Value, Aft => Decimals, Exp => 0);

        return Trim (Buffer, Left);
    exception
        when others =>
            return "0.0";
    end Image;

    --------------------------------------------------

    function Timestamp return String is
        -- The same count of seconds the ring buffer writes, so both exports carry the same time
        Now : constant Interfaces.C.long_long :=
            Ada.Calendar.Conversions.To_Unix_Time_64 (Clock);
    begin
        -- Ada writes a space in front of a positive number, which is cut off here
        return Trim (Interfaces.C.long_long'Image (Now), Left);
    exception
        when others =>
            return "";
    end Timestamp;

end PowerJoular.Formatting;
