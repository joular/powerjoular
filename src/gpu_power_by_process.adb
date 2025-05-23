with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib;           use GNAT.OS_Lib;
with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Command_Line;

with Nvidia_SMI; use Nvidia_SMI;

procedure Gpu_Power_By_Process is

   type PID_Type is new Integer;

   type SM_Usage is record
      PID : PID_Type;
      SM  : Float;
   end record;

   package SM_Vector is new
     Ada.Containers.Vectors (Index_Type => Natural, Element_Type => SM_Usage);
   use SM_Vector;

   -- Helper to execute a shell command and return the output as string
   function Execute_Command (Command : String) return String is
      Output : String (1 .. 10_000);
      Len    : Integer;
   begin
      Len := GNAT.OS_Lib.Shell (Command, Output'Address, Output'Length);
      return Output (1 .. Len);
   end Execute_Command;

   -- Get the SM usage per PID from nvidia-smi pmon
   function Get_SM_By_PID return SM_Vector.Vector is
      Raw_Output : constant String := Execute_Command ("nvidia-smi pmon -s u"); -- run nvidia-smi pmon -s um pour plus d'info mémoire. 
      Lines      : SM_Vector.Vector;
      Line_Start : Positive := 1;
      Line_End   : Natural;
   begin
      declare
         Output_Lines : constant String := Raw_Output;
         use Ada.Strings.Fixed;
         Line         : String;
         Count        : Natural := 0;
      begin
         for L of Output_Lines'Range loop
            exit when Count > 1000;
            Line_End :=
              Index (Output_Lines (Line_Start .. Output_Lines'Last), ASCII.LF);
            exit when Line_End = 0;
            Line := Output_Lines (Line_Start .. Line_Start + Line_End - 2);
            Line_Start := Line_Start + Line_End;

            if Line'Length > 0 and then Line (1) /= '#' then
               declare
                  Tokens  : constant String := Line;
                  PID_Val : PID_Type :=
                    Integer'Value (Trim (Tokens (1 .. 5), Ada.Strings.Left));
                  SM_Val  : Float :=
                    Float'Value (Trim (Tokens (27 .. 30), Ada.Strings.Left));
               begin
                  Lines.Append ((PID => PID_Val, SM => SM_Val));
               exception
                  when others =>
                     null;  
               end;
            end if;
            Count := Count + 1;
         end loop;

         return Lines;
      end;
   end Get_SM_By_PID;

   -- Compute GPU consumption for a specific PID
   function Estimate_PID_Consumption (Target_PID : PID_Type) return Float is
      SM_Data     : SM_Vector.Vector := Get_SM_By_PID;
      Total_SM    : Float := 0.0;
      PID_SM      : Float := 0.0;
      Total_Power : Float := Float(Get_Nvidia_SMI_Power);  
   begin
      for Usage of SM_Data loop
         Total_SM := Total_SM + Usage.SM;
         if Usage.PID = Target_PID then
            PID_SM := PID_SM + Usage.SM;
         end if;
      end loop;

      if Total_SM = 0.0 then
         return 0.0;
      end if;

      --  return (PID_SM / Total_SM) * Total_Power;
      return (PID_SM * Total_Power) / Total_SM;
   end Estimate_PID_Consumption;

begin
   if Ada.Command_Line.Argument_Count < 1 then
      Put_Line ("Usage: gpu_power_by_process <PID>");
      return;
   end if;

   declare
      PID             : PID_Type :=
        Integer'Value (Ada.Command_Line.Argument (1));
      Estimated_Conso : Float := Estimate_PID_Consumption (PID);
   begin
      Put_Line
        ("Estimated GPU Power Consumption for PID "
         & PID'Image
         & ": "
         & Estimated_Conso'Image
         & " W");
   end;
end Gpu_Power_By_Process;


