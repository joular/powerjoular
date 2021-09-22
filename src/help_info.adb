--
--  Copyright (c) 2020-2021, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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

package body Help_Info is

    procedure Show_Help is
    Version_Number : constant String := "0.1 beta";
    begin
        Put_Line (ESC & "[93m" & "~~ PowerJoular ~~" & ESC & "[0m");
        Put_Line ("Version " & Version_Number);
        Put_Line ("--------------------------");
        Put_Line ("PowerJoular is a multi-platform power monitoring tool");
        Put_Line ("It estimates power consumption every second based on:");
        Put_Line("- Processor and SOC for Intel processors (since Sandy Bridge) using RAPL");
        Put_Line("- NVIDIA GPUs using NVIDIA SMI if power monitoring is supported by the GPU model");
        --Put_Line("- Processor for Raspberry Pi using a regression model");
        Put_Line ("--------------------------");
        Put_Line (ESC & "[93m" & "Usage:" & ESC & "[0m");
        --Put_Line (HT & "powerjoular (for Raspberry Pi)");
        Put_Line (HT & "sudo powerjoular (for Intel requires root/sudo)");
        Put_Line ("--------------------------");
        Put_Line (ESC & "[93m" & "Options:" & ESC & "[0m");
        Put_Line (HT & "-h: show this help message");
        Put_Line (HT & "-p pid: specifiy a particular PID to monitor");
        Put_Line (HT & "-f filename: save monitoring data to the given filename path");
        Put_Line (HT & "-o filename: save only last monitoring data to the given filename path (file overwritten with only latest power measures)");
        Put_Line (HT & "-t: print data to the terminal");
        --Put_Line (HT & "-u: update Raspberry Pi power models from the internet (saves to /etc/powerjoular/powerjoular_models.json). Requires root/sudo");
        --Put_Line (HT & "-l: use linear regression models (less accurate than the default polynomial models) for Raspberry Pi energy models");
        Put_Line ("You can mix options, i.e., powerjoular -tp 144 --> monitor PID 144 and will print to the terminal");
        Put_Line ("--------------------------");
        Put_Line (ESC & "[93m" & "Daemons/Systemd service:" & ESC & "[0m");
        Put_Line ("When installing the tool, a systemd service can also be installed. The service runs PowerJoular using the -o option and saves power data to /tmp/powerjoular-service.csv");
        Put_Line ("Service can be started using: systemctl start powerjoular.service, and can be enabled to run on boot with: systemctl enable powerjoular.service");
        Put_Line ("--------------------------");
        Put_Line (ESC & "[93m" & "About:" & ESC & "[0m");
        Put_Line ("PowerJoular is written and maintained by Dr Adel Noureddine from the University of Pau and the Pays de l'Adour");
        Put_Line ("--------------------------");
        Put_Line (ESC & "[93m" & "Copyright:" & ESC & "[0m");
        Put_Line ("Copyright (c) 2020-2021, Adel Noureddine. PowerJoular is licensed under the GNU GPL 3 license only (GPL-3.0-only)");
    end;

end Help_Info;
