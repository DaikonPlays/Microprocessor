module PC_LUT #(parameter D=12)(
  input       [4:0] addr,	   // target 4 values
  input [3:0] instr,
  input logic zero,
		sign,
  input [11:0] prog_ctr,
  //input instr
  output logic absj,
  output logic[D-1:0] target);
  logic[4:0] newadd;
	//if instr is jeq
	//	if zero 
	//		run the rest 
	always_comb begin
		absj = 0;
		if (instr == 1100) begin
			if(!sign || zero) begin
				newadd = addr;
				absj = 1;
			end
			else newadd = 0;
		end
		if (instr == 1101) begin
			if(sign || zero) begin
				newadd = addr;
				absj = 1;
			end
			else newadd = 0;
		end	
	end

  always_comb case(newadd)
    0: target = prog_ctr;   // go back 5 spaces
	1: target = 42;   // go ahead 20 spaces
	2: target = 39;   // go back 1 space   1111_1111_1111
	default: target = 'b0;  // hold PC  
  endcase

endmodule

/*

	   pc = 4    0000_0000_0100	  4
	             1111_1111_1111	 -1

                 0000_0000_0011   3

				 (a+b)%(2**12)


   	  1111_1111_1011      -5
      0000_0001_0100     +20
	  1111_1111_1111      -1
	  0000_0000_0000     + 0


  */
