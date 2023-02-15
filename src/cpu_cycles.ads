--
--  Copyright (c) 2020-2023, Adel Noureddine, Universit� de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

package CPU_Cycles is

    -- Type to store CPU cycles data
    type CPU_Cycles_Data is
        record
            cuser : Long_Integer; -- Time spend in user mode
            cnice : Long_Integer; -- Time spent in user mode with low priority
            csystem : Long_Integer; -- Time spent in system mode
            cidle : Long_Integer; -- Time spent in the idle task
            cbusy : Long_Integer := 0; -- cbusy = cuser + cnice + csystem
            ctotal : Long_Integer := 0; -- ctotal = cuser + cnice + csystem + cidle
        end record;
    
    -- Calculte entire CPU cycles
    procedure Calculate_CPU_Cycles (CPU_Data : in out CPU_Cycles_Data);

end CPU_Cycles;
