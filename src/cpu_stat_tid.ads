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

with CPU_STAT_PID; use CPU_STAT_PID;

package CPU_STAT_TID is
    
    -- Calculate PID CPU time using TIDs
    procedure Calculate_PID_Time_TID (PID_Data : in out CPU_STAT_PID_Data; Is_Before : in Boolean);

end CPU_STAT_TID;
