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
-- As no hardware energy is available directly inside the VM, we read a shared file between host and guest which indicated the CPU power of the VM machine
package PowerJoular.Virtual_Machine is

    -- Whether the given name is one of the formats the shared file can be in
    -- 'powerjoular' is the 3 column CSV that PowerJoular writes with the -o option for a monitored process,
    --   timestamp, CPU load and power, the power being the third column
    --   It is the file carrying the process number, the one holding the power of the virtual machine, and not
    --   the file of the whole host machine, whose third column is the total power of the host instead
    -- 'watts' is a single column with only the power consumption
    function Is_Known_Format (Name : in String) return Boolean;

    -- The power of this machine, in watts, read from the shared file
    -- A file that can't be read keeps the value of the previous cycle, and is reported once
    function Power (File_Name : in String; Format : in String) return Long_Float;

end PowerJoular.Virtual_Machine;
