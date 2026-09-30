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

with Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with CPU_Load;
with Joular_Core;

with PowerJoular.Virtual_Machine;

package body PowerJoular.Monitor is

    -- The command line, kept from Start
    Settings : Options.Settings;

    -- The hardware sources Joular Core can read
    Available : Joular_Core.Source_List := (others => False);

    -- CPU load sample and time at the start of the current cycle
    Previous_Sample : CPU_Load.Sample;
    Previous_Time : Time;

    Unix_Epoch : constant Ada.Calendar.Time := Ada.Calendar.Formatting.Time_Of (1970, 1, 1, 0.0, Time_Zone => 0);

    --------------------------------------------------

    -- Seconds since 1970-01-01 UTC, rounded down as Unix does
    function Unix_Time return Long_Long_Integer is
        Elapsed : constant Duration := Ada.Calendar."-" (Ada.Calendar.Clock, Unix_Epoch);
    begin
        return Long_Long_Integer (Long_Long_Float'Floor (Long_Long_Float (Elapsed)));
    end Unix_Time;

    --------------------------------------------------

    -- One CPU load sample, of the whole system and of the monitored process or application
    function Take_Sample return CPU_Load.Sample is
    begin
        case Settings.Target is
            when Whole_System => return CPU_Load.Take;
            when One_Process => return CPU_Load.Take (Settings.PID);
            when One_Application => return CPU_Load.Take (To_String (Settings.App));
        end case;
    end Take_Sample;

    --------------------------------------------------

    -- A measurement in watts
    -- Some hardware reports the energy consumed since the previous reading, some the power drawn
    function Watts (Value : in Joular_Core.Measurement; Elapsed : in Duration) return Long_Float is
    begin
        if not Value.Available then
            return 0.0;
        end if;

        case Value.Unit is
            when Joular_Core.Power =>
                return Value.Value;

            when Joular_Core.Energy =>
                return (if Elapsed > 0.0 then Value.Value / Long_Float (Elapsed) else 0.0);
        end case;
    end Watts;

    --------------------------------------------------

    procedure Start (Config : in Options.Settings) is
        First_Reading : Joular_Core.Reading;
    begin
        Settings := Config;

        -- Inside a virtual machine the CPU can't be measured, but the GPU may have been passed through
        Joular_Core.Open ((Joular_Core.CPU => not Settings.Read_VM, Joular_Core.GPU => True));

        -- Same order as in Measure; the reading also starts the energy counters of the first cycle
        Previous_Sample := Take_Sample;
        Previous_Time := Clock;
        First_Reading := Joular_Core.Read;

        for Item in Joular_Core.Source loop
            Available (Item) := First_Reading (Item).Available;
        end loop;
    end Start;

    --------------------------------------------------

    function CPU_Available return Boolean is (Available (Joular_Core.CPU));

    function GPU_Available return Boolean is (Available (Joular_Core.GPU));

    --------------------------------------------------

    procedure Measure (Data : out Cycle) is
        -- Read back to back, so the load and the hardware cover the same time
        Sample : constant CPU_Load.Sample := Take_Sample;
        Now : constant Time := Clock;
        Hardware : constant Joular_Core.Reading := Joular_Core.Read;

        Before : constant CPU_Load.Sample := Previous_Sample;
        Elapsed : constant Duration := To_Duration (Now - Previous_Time);
    begin
        -- Start the next cycle here, so it covers one cycle even if something below fails
        Previous_Sample := Sample;
        Previous_Time := Now;

        Data := (Time => Unix_Time, others => <>);
        Data.CPU_Usage := CPU_Load.System_Usage (Before, Sample);

        if Settings.Target /= Whole_System then
            -- CPU Load gives a negative load when the process or application could not be read
            Data.Target_Usage := CPU_Load.Process_Usage (Before, Sample);

            if Data.Target_Usage < 0.0 then
                Data.Target_Usage := Unreadable;
            end if;
        end if;

        if Settings.Read_VM then
            Data.CPU_Power := Virtual_Machine.Power (To_String (Settings.VM_File), Settings.VM_Format);
        else
            Data.CPU_Power := Watts (Hardware (Joular_Core.CPU), Elapsed);
        end if;

        Data.GPU_Power := Watts (Hardware (Joular_Core.GPU), Elapsed);
        Data.Total_Power := Data.CPU_Power + Data.GPU_Power;

        -- The CPU power shared out by the part of the CPU load that is the monitored process or application
        if Is_Unreadable (Data.Target_Usage) then
            Data.Target_Power := Unreadable;
        elsif Data.CPU_Usage > 0.0 then
            Data.Target_Power := Long_Float'Min (Data.CPU_Power, Data.CPU_Power * Data.Target_Usage / Data.CPU_Usage);
        end if;
    end Measure;

    --------------------------------------------------

    procedure Stop is
    begin
        Joular_Core.Close;
    end Stop;

end PowerJoular.Monitor;
