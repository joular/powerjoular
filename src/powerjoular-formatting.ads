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

package PowerJoular.Formatting is

    -- Convert numbers in plain digits, and not in the exponent notation Ada uses by default
    -- Decimals is how many digits are kept after the dot
    function Image (Value : in Long_Float; Decimals : in Natural) return String;

    -- The current time as a count of seconds since the first of January 1970
    function Unix_Time return Long_Long_Integer;

    -- The current time as a Unix timestamp
    function Timestamp return String;

end PowerJoular.Formatting;
