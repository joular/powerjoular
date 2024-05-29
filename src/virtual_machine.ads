with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
package Virtual_Machine is

   function Calculate_VM_Consumption(File_Name : Unbounded_String; Power_Format : Unbounded_String) return float;

end Virtual_Machine;
