// combinational -- no clock
// sample -- change as desired
module alu(
  input[3:0] alu_cmd,    // ALU instructions
  input[7:0] inA, inB,	 // 8-bit wide data path
  input      sc_i,       // shift_carry in
  input[2:0]		 sv,
  output logic[7:0] result,
  output logic sc_o,     // shift_carry out
  //             pari,     // reduction XOR (output)
	//		         zero,      // NOR (output)
               zeroflg, 
               sign, 
               carry, 
               overflow
);
logic [7:0] temp_result;
logic [8:0] extended_result;
always_comb begin 
  result = 8'b0;
  temp_result = 8'b0;
  extended_result = 9'b0;
  sc_o = 0;
  zeroflg = 0;
  sign = 0;
  carry = 0;
  overflow = 0; 
  //zero = !result;
  //pari = ^result;
  //1001 immediate 5 bit
  //use that as address for PC LUT
  //result = inA[0] + inA[1] .... inA[7]
  case(alu_cmd)
    // 4'b0000: result = inA & inB;     // logical AND
    4'b0000: begin //Count_bits
      result = inA[0];
      for(int i = 1; i < 8; i++) begin
        result = inA[i] + result;
      end
    end
    4'b0001: result = inA | inB;     // logical OR
    4'b0010: result = inA ^ inB;     // logical XOR
    //4'b0011: {result,sc_o} = {inA,sc_i};    // logical shift left
	4'b0011: result = inA << sv;
	4'b0100: result = inA >> sv;
    //4'b0100: {result,sc_o} = {sc_i,inA};    // logical shift right
    4'b0101: {sc_o,result} = inA - inB + sc_i; // subtraction
   // 4'b0110: {sc_o,result} = inA + inB + sc_i;    // addition
	4'b0110: result = inA + inB;
    4'b0111: begin               // compare
      temp_result = inA - inB;
      if(temp_result == 0) begin
        zeroflg = 1;
      end else begin
        zeroflg = 0;
      end
      sign = temp_result[7]; 
      if (inA < inB) begin 
        carry = 1;
      end else begin
        carry = 0;
      end
      overflow = ((inA[7] != inB[7]) && (temp_result[7] != inA[7]));
    end
    4'b1000: result = inB;         // move 1
    4'b1001: result = inA;         // move 2
    default: result = 0;         // default case
  endcase
end
   
endmodule