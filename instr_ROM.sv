// lookup table
// deep 
// 9 bits wide; as deep as you wish
module instr_ROM #(parameter D=12)(
  input       [D-1:0] prog_ctr,    // prog_ctr	  address pointer
  output logic[ 8:0] mach_code);

  logic[8:0] core[2**D];
  initial							    // load the program
    $readmemb("H:/CSE 141L/sample.txt",core);

  always_comb mach_code = core[prog_ctr];
  //initial begin
    //forever begin
      //$display("Machine Code at %0d: %h", prog_ctr, mach_code);
    //end
  //end
 

endmodule


/*
sample mach_code.txt:

001111110		 // ADD r0 r1 r0
001100110
001111010
111011110
101111110
001101110
001000010
111011110
*/
//reads text file, core = instruction memory. add 1 to prog_ctr to move instructions. goes to control.sv