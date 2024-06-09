// sample top level design
module top_level(
  input        clk, reset, req, 
  input logic [1:0] jump_addr,
  output logic done);
  parameter D = 12,             // program counter width
    A = 3;             		  // ALU command bit width
  wire[D-1:0] target, 			  // jump 
              prog_ctr;
  wire        RegWrite;
  wire[7:0]   datA,datB,		  // from RegFile
              muxB, 
              muxC,
              regfile_in
			  rslt,               // alu output
              immed;
  logic sc_in,   				  // shift/carry out from/to ALU
   		pariQ,              	  // registered parity flag from ALU
		zeroQ;                    // registered zero flag from ALU 
  wire  relj;                     // from control to PC; relative jump enable
  wire  pari,
        zero,
		sc_clr,
		sc_en,
    regdist,
    MemtoReg.
        MemWrite,
        ALUSrc;		              // immediate switch
  wire[A-1:0] alu_cmd;
  wire[8:0]   mach_code;          // machine code
  wire[2:0] rd_addrA, rd_adrB, rd_addrSwitch;    // address pointers to reg_file
  logic [3:0] instr;   
  
// fetch subassembly
  PC #(.D(D))                    
     pc1 (.reset        (reset),
          .clk          (clk),
          .reljump_en   (relj),
          .absjump_en   (absj),
          .target       (target),
          .prog_ctr     (prog_ctr));
// lookup table to facilitate jumps/branches
  PC_LUT #(.D(D))
    pl1 (.addr          (mach_code[4:0]),  
         .target        (target)); 
// contains machine code
  instr_ROM ir1(.prog_ctr (prog_ctr),
                .mach_code(mach_code));

// control decoder
  Control ctl1(.instr      (mach_code[8:5]),
               .RegDst     (regdist), 
               .Branch     (relj), 
               .MemWrite   (MemWrite),
               .ALUSrc     (ALUSrc),
               .RegWrite   (RegWrite),     
               .MemtoReg   (MemtoReg),
               .ALUOp      (alu_cmd));
  assign rd_addrA = mach_code[1:0];
  assign rd_addrB = (mach_code[8:5] == 4'b0110) ? {1'b0, mach_code[4:3]} : mach_code[4:2]; 
  //assign rd_addrB = mach_code[4:2]; //ternary operator to decide between 3 bits and 2 bits concate with 0 {0, machcode 4:3}
  //assign rd_addrB = (instr == 0110) ? mach_code[4:3] : mach_code[4:2];
  assign alu_cmd  = mach_code[8:5];
//1010_10_010
  reg_file #(.pw(3)) rf1(.dat_in(regfile_in),	   // loads, most ops
              .clk(clk)        ,
              .wr_en   (RegWrite),
              .rd_addrA(rd_addrA),
              .rd_addrB(rd_addrB),
              .wr_addr (rd_addrSwitch),      // in place operation
              .datA_out(datA),
              .datB_out(datB)); 

  assign muxB = ALUSrc? immed : datB;
  //data comes out of reg file and goes into alu, one reg file goes to data memory for address. store output of alu and datamemory goes to mux and ouput mux goes to regfile
//based on instruction, change mux
  //figure out how to choose between rslt and regfile_dat for reg_file and loadi because move for exmaple uses result to set
  //adjust wr_addr based on operation
  //
  // always_comb begin
  //   if (instr == 0110) begin
  //     sel_regfile_input = 2'b01;
  //     loadimmed = mach_code[2:0];
  //   end
  //   else if(instr == 1110) begin
  //     regfile_in = rslt;
  //     rd_addrSwitch = rd_addrB;
  //   end
  //   else if(instr == 1010) begin
  //     regfile_in = rslt;
  //     rd_addrSwitch = rd_addrA;
  //   end
  //   else if(instr == 1000) begin //load
  //     regfile_in = regfile_dat;
  //     rd_addrSwitch = rd_addrB;
  //   end
  //   else if(instr == 0110) begin //loadi
  //     regfile_in = machcode[2:0];
  //     rd_addrSwitch = {1'0, machcode[4:3]}; //designate reg 010 for loading immediates
      
  //   end
  //   else if(instr >= 1111) begin
  //     regfile_in = rslt;
  //     rd_addrSwitch = rd_addrB;
  //   end
  // end
  101010101
  011001101
  always_comb begin
    instr = mach_code[8:5];
    if (instr == 4'b0110) begin // loadi
      regfile_in = mach_code[2:0];
      rd_addrSwitch = {1'b0, mach_code[4:3]}; // designate reg 010 for loading immediates
    end else if(instr == 4'b1110) begin //move into reg B
      regfile_in = rslt;
      rd_addrSwitch = rd_addrB;
    end else if(instr == 4'b1010) begin //move into reg A
      regfile_in = rslt;
      rd_addrSwitch = rd_addrA;
    end else if(instr == 4'b1000) begin // load
      regfile_in = regfile_dat;
      rd_addrSwitch = rd_addrB;
    end else if(instr >= 4'b1111) begin //default
      regfile_in = rslt;
      rd_addrSwitch = rd_addrB;
    end
  end
  alu alu1(.ALUOp       (alu_cmd),
          .inA    (datA),
          .inB    (muxB),
          .sc_i   (sc),
          .sc_o   (sc_o),
          .result      (rslt),
          .zeroflg     (zeroflg),
          .sign        (sign),
          .carry       (carry),
          .overflow    (overflow));  


  dat_mem dm1(.dat_in    (datA),  // from reg_file
              .clk       (clk),
              .wr_en     (MemWrite), // stores
              .addr      (datB),
              .dat_out   (regfile_dat));
// registered flags from ALU
  always_ff @(posedge clk) begin
      if (reset) begin
      pariQ <= 1'b0;
      zeroQ <= 1'b0;
      sc_in <= 1'b0;
      end else begin
        pariQ <= pari;
      zeroQ <= zero       
      end;
    if(sc_clr)
	  sc_in <= 'b0;
    else if(sc_en)
      sc_in <= sc_o;
  end
//set done to 1 when finished
  assign done = prog_ctr == 128;
 
endmodule