// control decoder
module Control #(
    parameter opwidth = 4, 
    mcodebits = 4
)(
    input [mcodebits-1:0] instr,    // subset of machine code (any width you need)
   // input zeroflg, 
    //input sign, 
    //input carry, 
   // input overflow,
    output logic RegDst, 
    output logic Branch, 
    output logic MemtoReg, 
    output logic MemWrite, 
    output logic ALUSrc, 
    output logic RegWrite,
    output logic [opwidth-1:0] ALUOp  // Correct the bit width declaration
    //output logic [1:0] jump_addr     // Remove unnecessary semicolon
);

//and r0, r1

always_comb begin
// defaults
  RegDst 	=   'b0;   // 1: not in place  just leave 0
  Branch 	=   'b0;   // 1: branch (jump)
  MemWrite  =	'b0;   // 1: store to memory
  ALUSrc 	=	'b0;   // 1: immediate  0: second reg file output
  RegWrite  =	'b1;   // 0: for store or no op  1: most other operations 
  MemtoReg  =	'b0;   // 1: load -- route memory instead of ALU to reg_file data in
  ALUOp	    =   'b1110; // y = a+0; what operation to perform
// sample values only -- use what you need
case(instr)    // override defaults with exceptions
  'b1111:  begin					// store operation
               MemWrite = 'b1;      // write to data mem
               RegWrite = 'b0;      // typically don't also load reg_file
               ALUSrc = 'b1;
			 end
  'b1000:  begin				  // load
			   MemtoReg = 'b1;   
         ALUSrc = 'b1; 
         RegWrite = 'b1;
        end
  'b0110: begin //loadi
     		 MemtoReg = 'b1;    
         ALUSrc = 'b1; 
         RegWrite = 'b1;
  end
  'b0000: begin  // logical count bit
    ALUOp = 'b0000;  
  end
  'b0001: begin  // logical OR
    ALUOp = 'b0001;  
  end
  'b0010: begin  // logical XOR XOR wiht all 1s for twos complement and add 1
    ALUOp = 'b0010;  
  end
  'b0011: begin  // logical shift left
    ALUOp = 'b0011; 
  end
  'b0100: begin  // logical shift right
    ALUOp = 'b0100;  
  end
  'b0101: begin  // subtraction
    ALUOp = 'b0101;  
  end
  'b0111: begin  // addition
    ALUOp = 'b0110; 
  end
  'b1001: begin  // compare
    ALUOp = 'b0111; 
  end
  'b1010: begin  // move 1
    ALUOp = 'b1000;  
  end
  4'b1011: begin  //jump if equal
    Branch = 'b1; 
  end
  'b1100: begin  // jump if greater or equal
    Branch = 'b1;  
  end
  'b1101: begin  // jump if less than or equal
    Branch = 'b1;  
  end
  'b1110: begin  // move 2
    ALUOp = 'b1001; 
  end
// ...
endcase
/*change size of ports 

*/
end
	
endmodule