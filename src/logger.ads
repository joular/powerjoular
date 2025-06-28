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

with Ada.Text_IO; use Ada.Text_IO;

package Logger is

   -- Type for log level
   type Log_Level is (Debug, Info, Warn, Error);
   
   -- Initialize logger
   procedure Init (Log_File : String := "");
   
   -- Log information
   procedure Log (Level : Log_Level; Message : String);
   
   -- Close log (useful for file logging)
   procedure Close;
   
private
   Log_To_File : Boolean := False; -- Log to file or to terminal
   Log_Output : Ada.Text_IO.File_Type; -- If log to file, then write to this file

end Logger;
