--
--  Copyright (c) 2020-2026, Adel Noureddine.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Axel Terrier
--  Contributors : Adel Noureddine
--

-- Read the power of this machine when it is a virtual machine
-- The hardware can't be measured from inside a VM, so the host writes the power of the VM to a file shared with the guest
package PowerJoular.Virtual_Machine is

    -- PowerJoular_CSV : the 3 column CSV that -o writes for a monitored process, the one carrying the PID of the VM on the host
    -- Watts : the power only
    type File_Format is (PowerJoular_CSV, Watts);

    -- The format named Name on the command line ('powerjoular' or 'watts')
    -- Returns False if Name is not a known format
    function Format_Of (Name : in String; Format : out File_Format) return Boolean;

    -- Read the power, in watts, from the file
    -- Returns False if the file can't be opened, or doesn't hold a power value (a negative value counts as none)
    function Read (File_Name : in String; Format : in File_Format; Power : out Long_Float) return Boolean;

    -- The power read from the file
    -- A file that can't be read gives the last power read (zero if none) and is reported once, as the host may be rewriting it
    function Power (File_Name : in String; Format : in File_Format) return Long_Float;

end PowerJoular.Virtual_Machine;
