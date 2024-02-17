--
--  Copyright (c) 2020-2023, Adel Noureddine, Université de Pau et des Pays de l'Adour.
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
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package body Nvidia_SMI is

    function Get_Nvidia_SMI_Power return Long_Float is
        Command    : String          := "nvidia-smi --format=csv,noheader,nounits --query-gpu=power.draw";
        Args       : Argument_List_Access;
        Status     : aliased Integer;
        Subs : String_Split.Slice_Set; -- Used to slice the read data from stat file
        Seps : constant String := CR & LF; -- Seperator (space) for slicing string
        Slice_number_count : String_Split.Slice_Number;
        GPU_Energy : Long_Float := 0.0;
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
                String_Split.Create (S          => Subs, -- Store sliced data in Subs
                                     From       => Response, -- Read data to slice
                                     Separators => Seps, -- Separator (here space)
                                     Mode       => String_Split.Multiple);

                Slice_number_count := String_Split.Slice_Count (Subs);

                for I in 1 .. Slice_number_count loop
                    GPU_Energy := GPU_Energy + Long_Float'Value (String_Split.Slice (Subs, 1));
                end loop;

                return GPU_Energy;
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
            return Response /= "[N/A]";
        end;
    exception
        when others =>
            return False;
    end;

end Nvidia_SMI;
