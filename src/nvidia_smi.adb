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
with GNAT.Expect; use GNAT.Expect;
with GNAT.OS_Lib; use GNAT.OS_Lib;

package body Nvidia_SMI is

    function Get_Nvidia_SMI_Power return Float is
        Command    : String          := "nvidia-smi --format=csv,noheader,nounits --query-gpu=power.draw";
        Args       : Argument_List_Access;
        Status     : aliased Integer;
    begin
        Args := Argument_String_To_List (Command);
        declare
            Response : String :=
              Get_Command_Output
                (Command   => Args (Args'First).all,
                 Arguments => Args (Args'First + 1 .. Args'Last),
                 Input     => "",
                 Status    => Status'Access);
        begin
            Free (Args);
            if Response = "[N/A]" then
                return 0.0;
            else
                return Float'Value (Response);
            end if;
        end;
    exception
        when others =>
            return 0.0;
    end;

    function Check_Nvidia_Supported_System return Boolean is
        Command    : String          := "nvidia-smi --format=csv,noheader,nounits --query-gpu=power.draw";
        Args       : Argument_List_Access;
        Status     : aliased Integer;
    begin
        Args := Argument_String_To_List (Command);
        declare
            Response : String :=
              Get_Command_Output
                (Command   => Args (Args'First).all,
                 Arguments => Args (Args'First + 1 .. Args'Last),
                 Input     => "",
                 Status    => Status'Access);
        begin
            Free (Args);
            if Response = "[N/A]" then
                return False;
            else
                return True;
            end if;
        end;
    exception
        when others =>
            return False;
    end;

end Nvidia_SMI;
