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

package CPU_STAT_PID is

    -- Type to store PID CPU stat data
    type CPU_STAT_PID_Data is
        record
            utime : Long_Integer; -- User time
            stime : Long_Integer; -- System time
            total_time : Long_Integer; -- Total time
        end record;
    
    -- Calculate PID CPU time
    procedure Calculate_PID_Time (PID_Data : in out CPU_STAT_PID_Data; PID_Number : Integer);

end CPU_STAT_PID;
