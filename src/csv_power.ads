--
--  Copyright (c) 2020-2024, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

package CSV_Power is

    -- Save CPU utilization and power conusmption to CSV file
    procedure Save_To_CSV_File (Filename : String; Utilization : Long_Float; Total_Power : Long_Float; CPU_Power : Long_Float; GPU_Power : Long_Float; Overwrite_Data : Boolean);

    -- Save PID's CPU utilization and power conusmption to CSV file
    procedure Save_PID_To_CSV_File (Filename : String; Utilization : Long_Float; Power : Long_Float; Overwrite_Data : Boolean);

     -- Print CPU utilization, CPU, GPU and total power conusmption on the terminal
    procedure Show_On_Terminal (Utilization : Long_Float; Power : Long_Float; Previous_Power : Long_Float; CPU_Power : Long_Float; GPU_Power : Long_Float; GPU_Supported : Boolean);

    -- Print CPU utilization and CPU power conusmption on the terminal of monitored PID
    procedure Show_On_Terminal_PID (PID_Utilization : Long_Float; PID_Power : Long_Float; Utilization : Long_Float; Power : Long_Float; Is_PID : Boolean);

end CSV_Power;
