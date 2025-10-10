--
--  Copyright (c) 2020-2025, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

with Logger; use Logger;

package body Help_Info is

    Version_Number : constant String := "1.1.0";

    procedure Show_Help is
    begin
        Log(Info, ESC & "[93m" & "~~ PowerJoular ~~" & ESC & "[0m");
        Log(Info, "Version " & Version_Number);
        Log(Info, "--------------------------");
        Log(Info, "PowerJoular is a multi-platform power monitoring tool");
        Log(Info, "It estimates power consumption every second based on:");
        Log(Info, "- Processor and SOC for Intel processors (since Sandy Bridge) using RAPL, or AMD (Ryzen, EPYC)");
        Log(Info, "- NVIDIA GPUs using NVIDIA SMI if power monitoring is supported by the GPU model");
        --Log(Info, "- Processor for Raspberry Pi using a regression model");
        Log(Info, "--------------------------");
        Log(Info, ESC & "[93m" & "Usage:" & ESC & "[0m");
        --Log(Info, HT & "powerjoular (for Raspberry Pi)");
        Log(Info, HT & "sudo powerjoular (for Intel requires root/sudo)");
        Log(Info, "--------------------------");
        Log(Info, ESC & "[93m" & "Options:" & ESC & "[0m");
        Log(Info, HT & "-h: show this help message");
        Log(Info, HT & "-p pid: specifiy a particular PID to monitor");
        Log(Info, HT & "-a appName: specifiy a particular application name to monitor (will monitor all PIDs of the application)");
        Log(Info, HT & "-f filename: save monitoring data to the given filename path");
        Log(Info, HT & "-o filename: save only last monitoring data to the given filename path (file overwritten with only latest power measures)");
        Log(Info, HT & "-t: print data to the terminal");
        Log(Info, HT & "-l: use linear regression models (less accurate than the default polynomial models) for Raspberry Pi energy models");
        Log(Info, HT & "-m: specify a filename for the power consumption of the virtual machine");
        Log(Info, HT & "-s: specify the format of the VM power, either powerjoular format (generated with the -o option: 3 columns csv file with the 3rd containing the power consumption the VM), or watts format (1 column containing just the power consumption of the VM)");
        Log(Info, "You can mix options, i.e., powerjoular -tp 144 --> monitor PID 144 and will print to the terminal");
        Log(Info, HT & "-k: use TIDs to calculate PID stats instead of PID stat directly (Experimental feature)");
        Log(Info, HT & "-c: save timestamps in milliseconds (instead of just seconds) in the written CSV files");
        Log(Info, "--------------------------");
        Log(Info, ESC & "[93m" & "Daemons/Systemd service:" & ESC & "[0m");
        Log(Info, "When installing the tool, a systemd service can also be installed. The service runs PowerJoular using the -o option and saves power data to /tmp/powerjoular-service.csv");
        Log(Info, "Service can be started using: systemctl start powerjoular.service, and can be enabled to run on boot with: systemctl enable powerjoular.service");
        Log(Info, "--------------------------");
        Log(Info, ESC & "[93m" & "About:" & ESC & "[0m");
        Log(Info, "PowerJoular is written and maintained by Dr Adel Noureddine from the University of Pau and the Pays de l'Adour");
        Log(Info, "--------------------------");
        Log(Info, ESC & "[93m" & "Copyright:" & ESC & "[0m");
        Log(Info, "Copyright (c) 2020-2025, Adel Noureddine. PowerJoular is licensed under the GNU GPL 3 license only (GPL-3.0-only)");
    end;

    procedure Show_Version is
    begin
        Log(Info, Version_Number);
    end;

end Help_Info;
