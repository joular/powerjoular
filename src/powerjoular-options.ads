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

-- Read the command line into one record that the rest of the program can use
package PowerJoular.Options is

    -- Everything the command line can set
    type Settings is
        record
            -- What is monitored: the whole system, and which process or application
            Target : Target_Kind := Whole_System;
            PID : CPU_Load.Process_ID := 0;
            App : Unbounded_String;

            -- Print the power data on the terminal, and the system information on start up
            Show_Terminal : Boolean := False;
            Show_Debug : Boolean := False;

            -- Write the power data to a CSV file
            -- Overwrite keeps only the latest measurement in the file instead of adding to it
            Write_CSV : Boolean := False;
            CSV_File : Unbounded_String;
            Overwrite : Boolean := False;

            -- Write the power data to a shared memory ring buffer
            Write_Ring_Buffer : Boolean := False;

            -- Read the power of the machine from a file written by the host, when running inside a virtual machine
            Read_VM : Boolean := False;
            VM_File : Unbounded_String;
            VM_Format : Unbounded_String;
        end record;

    -- What the program should do once the command line is read
    type Outcome is
       (Run, -- Start monitoring
        Finished, -- Nothing left to do
        Rejected -- If there is any error in the command line, the error will be on the standard error
       );

    -- Read the command line into Config
    procedure Parse (Config : out Settings; Result : out Outcome);

    -- Path of the CSV file the monitored process or application is written to
    -- It is the main CSV filename with the process number or the application name added to it
    -- Returns the main CSV filename when only the whole system is monitored
    function Target_CSV_File (Config : in Settings) return String;

end PowerJoular.Options;
