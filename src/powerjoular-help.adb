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

with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Text_IO; use Ada.Text_IO;

with CPU_Load;
with Joular_Core;

package body PowerJoular.Help is

    -- Make the text in yellow and the terminal back to normal color
    function Title (Text : in String) return String is
        (ESC & "[93m" & Text & ESC & "[0m");

    -- A constant variable with a line to be reused
    Rule : constant String := "--------------------------";

    --------------------------------------------------

    procedure Show_Help is
    begin
        Put_Line (Title ("~~ PowerJoular ~~"));
        Put_Line ("Version " & Version);
        Put_Line (Rule);
        Put_Line ("PowerJoular is a multi-platform power monitoring tool.");
        Put_Line ("It estimates the power consumption every second of:");
        Put_Line (HT & "- Intel (since Sandy Bridge) and AMD (Ryzen, EPYC) processors, through RAPL");
        Put_Line (HT & "- Raspberry Pi and Asus Tinker Board processors, through power models");
        Put_Line (HT & "- Apple Silicon Macs, the processor and the graphic card of the chip, through powermetrics");
        Put_Line (HT & "- Nvidia and AMD graphic cards, when the card reports its power");
        Put_Line (HT & "- One process, or one application and every process of it");
        Put_Line (Rule);
        Put_Line (Title ("Usage:"));
        Put_Line (HT & "powerjoular.exe (on Windows)");
        Put_Line (HT & "powerjoular (on Raspberry Pi)");
        Put_Line (HT & "sudo powerjoular (on macOS, as powermetrics needs elevated access. Only the Apple Silicon Macs are supported)");
        Put_Line (HT & "sudo powerjoular (on Linux, as RAPL needs elevated access. Otherwise give read rights to RAPL energy files)");
        Put_Line (Rule);
        Put_Line (Title ("Options:"));
        Put_Line (HT & "-h: show this help message");
        Put_Line (HT & "-v: show the version number");
        Put_Line (HT & "-t: print the power data on the terminal");
        Put_Line (HT & "-d: print the available hardware components on start up");
        Put_Line (HT & "-p pid: monitor the process with this PID number");
        Put_Line (HT & "-a appName: monitor this application, and every process of it");
        Put_Line (HT & "-f filename: export the power data to this file, in CSV format");
        Put_Line (HT & "-o filename: keep only the latest power data in this file (the file is overwritten every second)");
        Put_Line (HT & "-r: write the power data to a shared memory ring buffer, useful for another program to read with low latency");
        Put_Line (HT & "-m filename: read the power of this machine from the file the host writes, when running inside a virtual machine");
        Put_Line (HT & "-s format: format of that VM file, either 'powerjoular' (the 3 column CSV that -o writes for a monitored process, the power being the third column) or 'watts' (one column with the power only)");
        Put_Line (HT & HT & "with 'powerjoular', point -m at the file of the process the virtual machine runs as on the host, the one carrying the process number, and not at the file of the whole host machine");
        Put_Line ("You can mix the options, i.e., powerjoular -tp 144 monitors the process 144 and prints it on the terminal.");
        Put_Line (Rule);
        Put_Line (Title ("Ring buffer:"));
        Put_Line ("With -r, the power data of every second is written to a small shared memory area, which any program on the same machine can read with low latency.");
        Put_Line ("It holds a counter of 8 bytes followed by 5 entries of 48 bytes: the time of the measurement, then the CPU, GPU and total power, the CPU usage and the power of the monitored process or application.");
        Put_Line (Rule);
        Put_Line (Title ("Service (GNU/Linux only):"));
        Put_Line ("A systemd service is installed along with the program. It runs PowerJoular with the -o option, and writes the power data to /run/powerjoular/powerjoular-service.csv.");
        Put_Line ("Start it with: systemctl start powerjoular.service, and have it run on boot with: systemctl enable powerjoular.service");
        Put_Line (Rule);
        Put_Line (Title ("About:"));
        Put_Line ("PowerJoular is written and maintained by Prof. Adel Noureddine.");
        Put_Line ("It measures the hardware using the Joular Core library, and the CPU load using the CPU Load library.");
        Put_Line (Rule);
        Put_Line (Title ("Copyright:"));
        Put_Line ("Copyright (c) 2020-2026, Adel Noureddine. PowerJoular is licensed under the GNU GPL 3 license only (GPL-3.0-only).");
    end Show_Help;

    --------------------------------------------------

    procedure Show_Version is
    begin
        Put_Line (Version);
    end Show_Version;

    --------------------------------------------------

    procedure Show_System_Info (CPU_Available : in Boolean;
                                GPU_Available : in Boolean;
                                Ring_Buffer_Path : in String;
                                Using_Ring_Buffer : in Boolean) is
    begin
        Put_Line ("PowerJoular " & Version);
        Put_Line (HT & "Joular Core library: " & Joular_Core.Version);
        Put_Line (HT & "CPU Load library: " & CPU_Load.Version);
        Put_Line (HT & "CPU power: " & (if CPU_Available then "available" else "not available"));
        Put_Line (HT & "GPU power: " & (if GPU_Available then "available" else "not available"));

        if Using_Ring_Buffer then
            Put_Line (HT & "Ring buffer: " & Ring_Buffer_Path);
        end if;
    end Show_System_Info;

end PowerJoular.Help;
