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

with PowerJoular.Options;

-- Measure the power and the CPU load of the whole system, and of the monitored process or application
package PowerJoular.Monitor is

    -- Open the hardware sources, and take the first readings the first cycle is measured from
    procedure Start (Config : in Options.Settings);

    -- Whether Joular Core can measure the CPU and the GPU, once started
    function CPU_Available return Boolean;
    function GPU_Available return Boolean;

    -- Measure the cycle since the previous call, or since Start for the first one
    procedure Measure (Data : out Cycle);

    -- Close the hardware sources
    procedure Stop;

end PowerJoular.Monitor;
