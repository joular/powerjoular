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

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with CPU_Load;

with PowerJoular.Virtual_Machine;

-- Read the command line
package PowerJoular.Options is

    -- Everything the command line can set
    type Settings is
        record
            -- What is monitored on top of the whole system
            Target : Target_Kind := Whole_System;
            PID : CPU_Load.Process_ID := 0;
            App : Unbounded_String;

            -- Print the power data on the terminal, and the system information on start up
            Show_Terminal : Boolean := False;
            Show_Debug : Boolean := False;

            -- Write the power data to a CSV file
            -- Overwrite keeps only the latest measurement in the file
            Write_CSV : Boolean := False;
            CSV_File : Unbounded_String;
            Overwrite : Boolean := False;

            -- Write the power data to a shared memory ring buffer
            Write_Ring_Buffer : Boolean := False;

            -- Inside a virtual machine, read the CPU power from a file written by the host
            Read_VM : Boolean := False;
            VM_File : Unbounded_String;
            VM_Format : Virtual_Machine.File_Format := Virtual_Machine.Watts;
        end record;

    -- What to do once the command line is read
    type Outcome is
       (Run, -- Start monitoring
        Finished, -- Nothing left to do (help or version printed)
        Rejected -- The command line is wrong, and the error was printed on the standard error
       );

    procedure Parse (Config : out Settings; Result : out Outcome);

end PowerJoular.Options;
