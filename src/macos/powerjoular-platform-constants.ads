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

-- Values of the POSIX body of PowerJoular.Platform that are specific to macOS
private package PowerJoular.Platform.Constants is

    -- Flags of open, from fcntl.h
    O_CREAT : constant := 16#0200#;
    O_EXCL : constant := 16#0800#;

    Ring_Buffer_Path : constant String := "/tmp/powerjoular";

    No_Power_Source_Hint : constant String :=
        "On a Mac, reading powermetrics needs root: try 'sudo powerjoular'.";

end PowerJoular.Platform.Constants;
