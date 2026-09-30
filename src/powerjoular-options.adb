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

with Ada.Directories;
with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Command_Line; use GNAT.Command_Line;

with PowerJoular.Help;

package body PowerJoular.Options is

    Switches : constant String := "h v t d f: o: p: a: m: s: r";

    --------------------------------------------------

    procedure Refuse (Reason : in String) is
    begin
        Put_Line (Standard_Error, "powerjoular: " & Reason);
        Put_Line (Standard_Error, "Run 'powerjoular -h' to see the options.");
    end Refuse;

    --------------------------------------------------

    procedure Parse (Config : out Settings; Result : out Outcome) is
        Asked_For_Process : Boolean := False;
        Asked_For_Application : Boolean := False;
        Format_Name : Unbounded_String;
        Format_Known : Boolean := False;

        -- The first reason the options can't be used, or an empty string if they can
        function Problem return String is
            Extra : constant String := Get_Argument;
            VM_File : constant String := To_String (Config.VM_File);
            Ignored : Long_Float;
        begin
            if Extra /= "" then
                return "unexpected argument: " & Extra;
            elsif Asked_For_Process and then Asked_For_Application then
                return "monitor either a process (-p) or an application (-a), not both.";
            elsif Asked_For_Process and then Config.PID = 0 then
                return "-p takes the number of a running process, and 0 is not one.";
            elsif Asked_For_Application and then Config.App = Null_Unbounded_String then
                return "-a needs the name of an application to monitor.";
            elsif Config.Write_CSV and then Config.CSV_File = Null_Unbounded_String then
                return "-f and -o need the path of a file to write to.";
            elsif not Config.Read_VM then
                return "";
            elsif VM_File = "" then
                return "-m needs the path of the file the host writes the power of this machine to.";
            elsif not Ada.Directories.Exists (VM_File) then
                return "no such file: " & VM_File;
            elsif not Format_Known then
                return "-m needs -s with either 'powerjoular' or 'watts' as the format of the power file.";
            -- Read the file once now, so a file with the wrong format is refused at once
            elsif not Virtual_Machine.Read (VM_File, Config.VM_Format, Ignored) then
                return "no power value could be read from " & VM_File
                       & " in the '" & To_String (Format_Name) & "' format.";
            else
                return "";
            end if;
        end Problem;

    begin
        Config := (others => <>);
        Result := Rejected;

        loop
            case Getopt (Switches) is
                when 'h' =>
                    Help.Show_Help;
                    Result := Finished;
                    return;

                when 'v' =>
                    Help.Show_Version;
                    Result := Finished;
                    return;

                when 't' =>
                    Config.Show_Terminal := True;

                when 'd' =>
                    Config.Show_Debug := True;

                when 'r' =>
                    Config.Write_Ring_Buffer := True;

                when 'f' =>
                    Config.Write_CSV := True;
                    Config.CSV_File := To_Unbounded_String (Parameter);
                    Config.Overwrite := False;

                when 'o' =>
                    Config.Write_CSV := True;
                    Config.CSV_File := To_Unbounded_String (Parameter);
                    Config.Overwrite := True;

                when 'p' =>
                    begin
                        Config.PID := CPU_Load.Process_ID'Value (Parameter);
                    exception
                        when Constraint_Error =>
                            Refuse ("-p takes the number of a process to monitor.");
                            return;
                    end;

                    Config.Target := One_Process;
                    Asked_For_Process := True;

                when 'a' =>
                    Config.App := To_Unbounded_String (Parameter);
                    Config.Target := One_Application;
                    Asked_For_Application := True;

                when 'm' =>
                    Config.VM_File := To_Unbounded_String (Parameter);
                    Config.Read_VM := True;

                when 's' =>
                    Format_Name := To_Unbounded_String (Parameter);
                    Format_Known := Virtual_Machine.Format_Of (Parameter, Config.VM_Format);
                    Config.Read_VM := True;

                when others =>
                    exit;
            end case;
        end loop;

        declare
            Reason : constant String := Problem;
        begin
            if Reason /= "" then
                Refuse (Reason);
                return;
            end if;
        end;

        -- With no output asked for, print on the terminal
        if not Config.Write_CSV and then not Config.Write_Ring_Buffer then
            Config.Show_Terminal := True;
        end if;

        Result := Run;
    exception
        when Invalid_Switch =>
            Refuse ("unknown option: " & Full_Switch);

        when Invalid_Parameter =>
            Refuse ("option -" & Full_Switch & " needs a value.");
    end Parse;

end PowerJoular.Options;
