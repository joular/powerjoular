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
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Command_Line; use GNAT.Command_Line;

with PowerJoular.Help;
with PowerJoular.Virtual_Machine;

package body PowerJoular.Options is

    -- Where the power data goes when no filename is given
    Default_CSV_File : constant String := "./powerjoular-power.csv";

    -- The command line parameters
    Switch_List : constant String := "h v t d f: o: p: a: m: s: r";

    --------------------------------------------------

    -- Print why the command line can't be used
    procedure Refuse (Reason : in String) is
    begin
        Put_Line (Standard_Error, "powerjoular: " & Reason);
        Put_Line (Standard_Error, "Run 'powerjoular -h' to see the options.");
    end Refuse;

    --------------------------------------------------

    procedure Parse (Config : out Settings; Result : out Outcome) is
        Asked_For_Process : Boolean := False;
        Asked_For_Application : Boolean := False;
    begin
        Config := (others => <>);
        Config.CSV_File := To_Unbounded_String (Default_CSV_File);
        Result := Rejected;

        loop
            case Getopt (Switch_List) is
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
                    Config.CSV_File := To_Unbounded_String (Parameter);
                    Config.Write_CSV := True;
                    Config.Overwrite := False;

                when 'o' =>
                    Config.CSV_File := To_Unbounded_String (Parameter);
                    Config.Write_CSV := True;
                    Config.Overwrite := True;

                when 'p' =>
                    Config.Target := One_Process;
                    Config.PID := CPU_Load.Process_ID'Value (Parameter);
                    Asked_For_Process := True;

                when 'a' =>
                    Config.Target := One_Application;
                    Config.App := To_Unbounded_String (Parameter);
                    Asked_For_Application := True;

                when 'm' =>
                    Config.VM_File := To_Unbounded_String (Parameter);
                    Config.Read_VM := True;

                when 's' =>
                    Config.VM_Format := To_Unbounded_String (Parameter);
                    Config.Read_VM := True;

                when others =>
                    exit;
            end case;
        end loop;

        -- Check verifications

        declare
            Extra : constant String := Get_Argument;
        begin
            if Extra /= "" then
                Refuse ("unexpected argument: " & Extra);
                return;
            end if;
        end;

        if Asked_For_Process and then Asked_For_Application then
            Refuse ("monitor either a process (-p) or an application (-a), not both.");
            return;
        end if;

        if Asked_For_Process and then Config.PID = 0 then
            Refuse ("-p takes the number of a running process, and 0 is not one.");
            return;
        end if;

        if Asked_For_Application and then Config.App = Null_Unbounded_String then
            Refuse ("-a needs the name of an application to monitor.");
            return;
        end if;

        if Config.Write_CSV and then Config.CSV_File = Null_Unbounded_String then
            Refuse ("-f and -o need the path of a file to write to.");
            return;
        end if;

        if Config.Read_VM then
            if Config.VM_File = Null_Unbounded_String then
                Refuse ("-m needs the path of the file the host writes the power of this machine to.");
                return;
            end if;

            if not Ada.Directories.Exists (To_String (Config.VM_File)) then
                Refuse ("no such file: " & To_String (Config.VM_File));
                return;
            end if;

            if not Virtual_Machine.Is_Known_Format (To_String (Config.VM_Format)) then
                Refuse ("-s takes either 'powerjoular' or 'watts' as the format of the power file.");
                return;
            end if;
        end if;

        -- If not CSV or ring buffer, and not terminal option provided, then show power values on the terminal
        if not Config.Show_Terminal
           and then not Config.Write_CSV
           and then not Config.Write_Ring_Buffer
        then
            Config.Show_Terminal := True;
        end if;

        Result := Run;
    exception
        when Invalid_Switch =>
            Refuse ("unknown option: " & Full_Switch);

        when Invalid_Parameter =>
            Refuse ("option -" & Full_Switch & " needs a value.");

        when Constraint_Error =>
            -- Only -p converts its parameter to a number, so this means PID given was not a number
            Refuse ("-p takes the number of a process to monitor.");
    end Parse;

    --------------------------------------------------

    -- The name of an application ends up inside a filename, and a name is free to hold anything at all
    -- Folder separators are taken out of it, so the file lands where the given path says and nowhere else
    function As_Filename_Part (Name : in String) return String is
        Result : String := Name;
    begin
        for I in Result'Range loop
            if Result (I) = '/' or else Result (I) = '\' then
                Result (I) := '_';
            end if;
        end loop;

        return Result;
    end As_Filename_Part;

    --------------------------------------------------

    function Target_CSV_File (Config : in Settings) return String is
        Base : constant String := To_String (Config.CSV_File);
    begin
        case Config.Target is
            when Whole_System =>
                return Base;

            when One_Process =>
                return Base & "-"
                       & Trim (CPU_Load.Process_ID'Image (Config.PID), Left)
                       & ".csv";

            when One_Application =>
                return Base & "-" & As_Filename_Part (To_String (Config.App)) & ".csv";
        end case;
    end Target_CSV_File;

end PowerJoular.Options;
