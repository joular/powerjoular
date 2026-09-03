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
with Ada.Calendar.Formatting;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;

package body PowerJoular.Formatting is

    -- Ada writes floats in the exponent notation by default, this writes them in plain digits
    package Value_IO is new Ada.Text_IO.Float_IO (Long_Float);

    -- Midnight of the first of January 1970, in UTC, the moment Unix time counts from
    -- The time zone is spelled out, so the count is the same wherever the machine sits
    Epoch : constant Time :=
        Ada.Calendar.Formatting.Time_Of (1970, 1, 1, 0.0, Time_Zone => 0);

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

    function Unix_Time return Long_Long_Integer is
        Elapsed : constant Duration := Clock - Epoch;
    begin
        -- The part of the second that has already passed is dropped, and not rounded up, the way Unix counts
        return Long_Long_Integer (Long_Long_Float'Floor (Long_Long_Float (Elapsed)));
    exception
        when others =>
            return 0;
    end Unix_Time;

    --------------------------------------------------

    function Timestamp return String is
        -- The same count of seconds the ring buffer writes, so both exports carry the same time
        Now : constant Long_Long_Integer := Unix_Time;
    begin
        -- Ada writes a space in front of a positive number, which is cut off here
        return Trim (Long_Long_Integer'Image (Now), Left);
    exception
        when others =>
            return "";
    end Timestamp;

end PowerJoular.Formatting;
