with Ada.Containers.Vectors;

package Gpu_Power_By_Process is

   type PID_Type is new Integer;

   type SM_Usage is record
      PID : PID_Type;
      SM  : Float;
   end record;

   package SM_Vector is new Ada.Containers.Vectors (Index_Type => Natural, Element_Type => SM_Usage);

   -- Exécute une commande shell et retourne la sortie sous forme de chaîne
   -- revoir ? 
   function Execute_Command (Command : String) return String;

   -- Récupère l'utilisation SM par PID à partir de nvidia-smi pmon
   function Get_SM_By_PID return SM_Vector.Vector;

   -- Estime la consommation GPU d'un processus donné (PID)
   function Estimate_PID_Consumption (Target_PID : PID_Type) return Float;

end Gpu_Power_By_Process;