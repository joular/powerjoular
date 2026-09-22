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

-- Write every cycle measurement to a shared memory ring buffer, so another program on the same machine can read the power data with low latency
-- The ring buffer holds, in the byte order of the machine, a counter of 8 bytes followed by 5 entries of 48 bytes:
--     timestamp : 8 bytes, unsigned, Unix time in seconds
--     cpu power, gpu power, total power : 8 bytes each, IEEE doubles, in watts
--     cpu usage : 8 bytes, IEEE double, from 0.0 to 1.0
--     process or application power : 8 bytes, IEEE double, in watts, and -1 when the process or the application could not be read at all
-- A cycle is written in the entry the counter points at, and the counter is raised afterwards.
-- A reader follows the counter to know when a new cycle has landed, and the timestamps to know how old each entry is.
--
-- The area lives at /dev/shm/joularcorering on Linux, %PROGRAMDATA%\joularcorering on Windows
-- (C:\ProgramData\joularcorering unless the machine puts ProgramData elsewhere), and /tmp/joularcorering elsewhere
--
-- Only one PowerJoular should write to the ring buffer at a time. Two runs writing to it at once each keep a counter of their own, so a reader sees the entries of both interleaved and the counter moving backwards
package PowerJoular.Ring_Buffer is

    -- Create the shared memory ring, or use one if already there, and map it
    -- Returns False when it can't be done
    function Open return Boolean;

    -- Write one cycle in the next entry, or nothing when the ring was never opened
    procedure Write (Data : in Cycle);

    -- Close and free the ring buffer
    -- The ring buffer is a real file on every system, so it is left behind and a reader can still pick up the last entries written to it after PowerJoular has stopped
    procedure Close;

    -- The path of the ring buffer
    function Path return String;

end PowerJoular.Ring_Buffer;
