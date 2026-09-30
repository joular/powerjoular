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

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Exceptions;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;

with PowerJoular; use PowerJoular;
with PowerJoular.CSV;
with PowerJoular.Help;
with PowerJoular.Monitor;
with PowerJoular.Options; use PowerJoular.Options;
with PowerJoular.Platform;
with PowerJoular.Ring_Buffer;
with PowerJoular.Stop;
with PowerJoular.Terminal;

-- Read the command line, then measure once a cycle until Ctrl+C, and send each cycle to the outputs asked for
procedure PowerJoular_Main is

    Config : Settings;
    Result : Outcome;

    Interval : constant Time_Span := To_Time_Span (Cycle_Interval);

    -- End of the cycle being measured
    Deadline : Time;

    Data : Cycle;

    -- Only the first failed cycle is reported, not one every second
    Reported_Failure : Boolean := False;

    --------------------------------------------------

    -- Wait until Ending, waking up regularly to notice a Ctrl+C quickly
    procedure Wait_Until (Ending : in Time) is
        Step : constant Time_Span := Milliseconds (100);
        Next : Time := Clock + Step;
    begin
        while not Stop.Asked and then Next < Ending loop
            delay until Next;
            Next := Next + Step;
        end loop;

        if not Stop.Asked then
            delay until Ending;
        end if;
    end Wait_Until;

    --------------------------------------------------

    procedure Publish (Data : in Cycle) is
    begin
        if Config.Show_Terminal then
            Terminal.Show (Data, Config.Target, Monitor.GPU_Available);
        end if;

        if Config.Write_CSV then
            CSV.Write (Data);
        end if;

        if Config.Write_Ring_Buffer then
            Ring_Buffer.Write (Data);
        end if;
    end Publish;

    --------------------------------------------------

    procedure Shut_Down is
    begin
        Ring_Buffer.Close;
        Monitor.Stop;
        Terminal.Close_Line;
    end Shut_Down;

    --------------------------------------------------

begin
    Terminal.Enable_Escape_Sequences;

    Parse (Config, Result);

    case Result is
        when Finished =>
            return;

        when Rejected =>
            Set_Exit_Status (Failure);
            return;

        when Run =>
            null;
    end case;

    Stop.Install;

    Monitor.Start (Config);
    Deadline := Clock + Interval;

    if Config.Write_Ring_Buffer and then not Ring_Buffer.Open then
        Put_Line (Standard_Error,
                  "powerjoular: cannot open the ring buffer at " & Ring_Buffer.Path
                  & ", the monitoring goes on without it.");
        Config.Write_Ring_Buffer := False;
    end if;

    if Config.Write_CSV then
        CSV.Start (Config);
    end if;

    if Config.Show_Debug then
        Help.Show_System_Info (Config, Monitor.CPU_Available, Monitor.GPU_Available);
    end if;

    if not Config.Read_VM and then not Monitor.CPU_Available and then not Monitor.GPU_Available then
        Put_Line (Standard_Error, "powerjoular: no power source found on this machine.");
        Put_Line (Standard_Error, Platform.No_Power_Source_Hint);
        Shut_Down;
        Set_Exit_Status (Failure);
        return;
    end if;

    while not Stop.Asked loop
        Wait_Until (Deadline);
        exit when Stop.Asked;

        -- A failed cycle (a source that stops answering, a process that ends mid-reading) doesn't stop the monitoring
        begin
            Monitor.Measure (Data);
            Publish (Data);
        exception
            when E : others =>
                if not Reported_Failure then
                    Reported_Failure := True;
                    Terminal.Close_Line;
                    Put_Line (Standard_Error, "powerjoular: a cycle failed, the monitoring goes on.");
                    Put_Line (Standard_Error, Ada.Exceptions.Exception_Information (E));
                end if;
        end;

        -- After a sleep, or when far behind, start again from now instead of catching up
        Deadline := Deadline + Interval;

        if Deadline < Clock then
            Deadline := Clock + Interval;
        end if;
    end loop;

    Shut_Down;
exception
    when E : others =>
        Shut_Down;
        Put_Line (Standard_Error, "powerjoular: stopped on an unexpected error.");
        Put_Line (Standard_Error, Ada.Exceptions.Exception_Information (E));
        Set_Exit_Status (Failure);
end PowerJoular_Main;
