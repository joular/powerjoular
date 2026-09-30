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

with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;

package body PowerJoular.Formatting is

    package Value_IO is new Ada.Text_IO.Float_IO (Long_Float);

    function Image (Value : in Long_Float; Decimals : in Natural) return String is
        -- Wide enough for any power or load value
        Buffer : String (1 .. 64);
    begin
        Value_IO.Put (To => Buffer, Item => Value, Aft => Decimals, Exp => 0);
        return Trim (Buffer, Left);
    exception
        when Ada.Text_IO.Layout_Error =>
            -- Too large for the buffer in plain digits
            return Trim (Long_Float'Image (Value), Left);
    end Image;

end PowerJoular.Formatting;
