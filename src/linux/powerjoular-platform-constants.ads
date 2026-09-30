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

-- Values of the POSIX body of PowerJoular.Platform that are specific to Linux
private package PowerJoular.Platform.Constants is

    -- Flags of open, from fcntl.h (the same on x86 and ARM)
    O_CREAT : constant := 8#100#;
    O_EXCL : constant := 8#200#;

    -- /dev/shm is kept in memory and never written to a disk
    Ring_Buffer_Path : constant String := "/dev/shm/powerjoular";

    No_Power_Source_Hint : constant String :=
        "On a PC or a server, reading RAPL needs root: try 'sudo powerjoular'.";

end PowerJoular.Platform.Constants;
