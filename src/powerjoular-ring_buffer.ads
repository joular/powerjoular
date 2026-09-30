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

-- Write each cycle to a shared memory ring buffer, so another program on the same machine can read it with low latency
-- Layout, in the byte order of the machine: a counter of 8 bytes, then 5 entries of 48 bytes:
--     timestamp : unsigned 64 bits, Unix time in seconds
--     cpu power, gpu power, total power : IEEE doubles, in watts
--     cpu usage : IEEE double, from 0.0 to 1.0
--     process or application power : IEEE double, in watts, -1 when it could not be read
-- A cycle is written in entry (counter mod 5), then the counter is incremented
--
-- The file is /dev/shm/powerjoular on Linux, %PROGRAMDATA%\powerjoular on Windows and /tmp/powerjoular on macOS
-- It is created on each start, so a reader has to open it again when PowerJoular restarts
-- Only one PowerJoular should write to it at a time
package PowerJoular.Ring_Buffer is

    -- Create the ring buffer file and map it
    -- Returns False if it can't be done
    function Open return Boolean;

    -- Write one cycle in the next entry, or nothing if the ring buffer is not open
    procedure Write (Data : in Cycle);

    -- Unmap the ring buffer
    -- The file is left behind, so a reader can still get the last entries after PowerJoular stops
    procedure Close;

    function Path return String;

end PowerJoular.Ring_Buffer;
