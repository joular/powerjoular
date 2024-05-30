with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
package Virtual_Machine is

   function Read_VM_Power(File_Name : Unbounded_String; Power_Format : Unbounded_String) return Long_Float;

end Virtual_Machine;
