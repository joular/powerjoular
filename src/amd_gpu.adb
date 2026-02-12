--
--  Copyright (c) 2025-2026, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Expect; use GNAT.Expect;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with GNAT.String_Split; use GNAT;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Maps; use Ada.Strings.Maps;
with Ada.Strings; use Ada.Strings;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package body Amd_Gpu is

    function Extract_Value (Json_Str : String; Key : String) return Long_Float is
        Start_Index : Integer;
        End_Index   : Integer;
        Result      : Long_Float := 0.0;
        Idx         : Integer := Json_Str'First;
    begin
        loop
            Start_Index := Index (Json_Str, Key, Idx);
            exit when Start_Index = 0;
            
            -- Move index past key
            Idx := Start_Index + Key'Length;
            
            -- Find the value after the key. It should be after a colon.
            -- We look for the first digit or decimal point.
            while Idx <= Json_Str'Last and then 
                  (Json_Str (Idx) /= ':' and then 
                   Json_Str (Idx) /= '"' and then 
                   not (Json_Str (Idx) in '0' .. '9')) loop
                Idx := Idx + 1;
            end loop;

            if Idx > Json_Str'Last then
                return Result;
            end if;
            
            -- If we hit a colon, skip it and iterate again looking for value start
            if Json_Str (Idx) = ':' then
                Idx := Idx + 1;
                while Idx <= Json_Str'Last and then 
                      not (Json_Str (Idx) in '0' .. '9') loop
                    Idx := Idx + 1;
                end loop;
            end if;
            
            if Idx > Json_Str'Last then
                return Result;
            end if;

            -- Now extract the number
            End_Index := Idx;
            while End_Index <= Json_Str'Last and then 
                  (Json_Str (End_Index) in '0' .. '9' or else Json_Str (End_Index) = '.') loop
                End_Index := End_Index + 1;
            end loop;
            
            if End_Index > Idx then
                begin
                    Result := Result + Long_Float'Value (Json_Str (Idx .. End_Index - 1));
                exception
                    when others => null; -- Ignore parsing errors
                end;
            end if;
            
            Idx := End_Index;
        end loop;
        
        return Result;
    end Extract_Value;

    function Get_Amd_Gpu_Power return Long_Float is
        Command_Amd_Smi  : constant String := "amd-smi metric --json";
        Command_Rocm_Smi : constant String := "rocm-smi --showpower --json";
        Args             : Argument_List_Access;
        Status           : aliased Integer;
        Power            : Long_Float := 0.0;
        Use_Amd_Smi      : Boolean := False;
    begin
        -- Determine which command to use
        Args := Argument_String_To_List ("amd-smi --version");
        declare
             Response : String := "";
        begin
             begin
                 Response := Get_Command_Output
                    (Command   => Args (Args'First).all,
                     Arguments => Args (Args'First + 1 .. Args'Last),
                     Input     => "",
                     Status    => Status'Access);
                 if Status = 0 then
                     Use_Amd_Smi := True;
                 end if;
             exception
                 when others => null;
             end;
             Free (Args);
        end;

        if Use_Amd_Smi then
            Args := Argument_String_To_List (Command_Amd_Smi);
        else
            Args := Argument_String_To_List (Command_Rocm_Smi);
        end if;

        declare
            Response : String :=
              Get_Command_Output
                (Command   => Args (Args'First).all,
                 Arguments => Args (Args'First + 1 .. Args'Last),
                 Input     => "",
                 Status    => Status'Access);
        begin
            Free (Args);
            if Status /= 0 or else Response'Length = 0 then
                return 0.0;
            end if;

            -- Try different keys for power
            Power := Extract_Value (Response, """Average Graphics Package Power (W)""");
            if Power = 0.0 then
                Power := Extract_Value (Response, """average_socket_power""");
            end if;
            if Power = 0.0 then
                Power := Extract_Value (Response, """socket_power""");
            end if;
            if Power = 0.0 then
                Power := Extract_Value (Response, """current_socket_power""");
            end if;
            if Power = 0.0 then
                Power := Extract_Value (Response, """power""");
            end if;
            
            return Power;
        end;
    exception
        when others =>
            return 0.0;
    end Get_Amd_Gpu_Power;

    function Check_Amd_Supported_System return Boolean is
        Command_Amd  : constant String := "amd-smi --version";
        Command_Rocm : constant String := "rocm-smi --version";
        Args         : Argument_List_Access;
        Status       : aliased Integer;
    begin
        -- Check amd-smi
        Args := Argument_String_To_List (Command_Amd);
        begin
            declare
                Response : String :=
                  Get_Command_Output
                    (Command   => Args (Args'First).all,
                     Arguments => Args (Args'First + 1 .. Args'Last),
                     Input     => "",
                     Status    => Status'Access);
            begin
                Free (Args);
                if Status = 0 then
                    return True;
                end if;
            end;
        exception
            when others => Free (Args);
        end;

        -- Check rocm-smi
        Args := Argument_String_To_List (Command_Rocm);
        begin
            declare
                Response : String :=
                  Get_Command_Output
                    (Command   => Args (Args'First).all,
                     Arguments => Args (Args'First + 1 .. Args'Last),
                     Input     => "",
                     Status    => Status'Access);
            begin
                Free (Args);
                if Status = 0 then
                    return True;
                end if;
            end;
        exception
            when others => Free (Args);
        end;
        
        return False;
    end Check_Amd_Supported_System;

end Amd_Gpu;
