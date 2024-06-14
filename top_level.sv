// sample top level design
module top_level(
  input        clk, reset, start, 
  //req, 
  //input logic [1:0] jump_addr,
  output logic done);
  parameter D = 12,             // program counter width
    A = 4;             		  // ALU command bit width
  wire[D-1:0] target, 			  // jump 
              prog_ctr;
  wire        RegWrite;
  logic[7:0]   datA,datB,		  // from RegFile
              muxB, 
              muxC,
              regMux,
              regfile_in,
			  rslt,               // alu output
              immed;
  logic sc_in,   				  // shift/carry out from/to ALU
   		pariQ,              	  // registered parity flag from ALU
      sign,
      carry,
      overhead,
      absj,
		zeroQ;                    // registered zero flag from ALU 
  wire  relj;                     // from control to PC; relative jump enable
  wire  pari,
        zero,
		sc_clr,
		sc_en,
    regdist,
    MemtoReg,
        MemWrite,
        ALUSrc;		              // immediate switch
  wire[A-1:0] alu_cmd;
  wire[8:0]   mach_code;          // machine code
  logic[3:0] rd_addrA, rd_addrB;
  logic[3:0] rd_addrSwitch;
  logic [3:0] instr;   
  logic [2:0] sv;   
  logic[7:0] regfile_dat;

// fetch subassembly
  PC #(.D(D))                    
     pc1 (.reset        (reset),
          .clk          (clk),
          .absjump_en   (absj),
          .target       (target),
          .prog_ctr     (prog_ctr));
// lookup table to facilitate jumps/branches
  PC_LUT #(.D(D))
    pl1 (.addr          (mach_code[4:0]),  
         .instr(instr),
         .zero(zero),
         .sign(sign),
         .absj(absj),
         .prog_ctr(prog_ctr),
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
  
  //assign rd_addrB = mach_code[4:2]; //ternary operator to decide between 3 bits and 2 bits concate with 0 {0, machcode 4:3}
  //assign rd_addrB = (instr == 0110) ? mach_code[4:3] : mach_code[4:2];
  //assign alu_cmd  = mach_code[8:5];
//1010_10_010
  reg_file #(.pw(4)) rf1(.dat_in(regfile_in),	   // loads, most ops
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

//figure out how to asign rd_addrA and B to the right value
  always_comb begin
    instr = mach_code[8:5];
	  rd_addrB = {2'b10, mach_code[1:0]};
	  rd_addrA = {1'b0, mach_code[4:2]};
	  regfile_in = rslt;  
     rd_addrSwitch = rd_addrA;  
    sv = 5'b00000;  
    if(instr == 4'b0011 || instr == 4'b0100) begin
      sv = {5'b00000,mach_code[1:0]};
	  rd_addrB = {1'b0, mach_code[4:2]};
    end
    if (instr == 4'b0110) begin // loadi
      regfile_in = {5'b00000,mach_code[2:0]};
      rd_addrSwitch = {2'b10, mach_code[4:3]}; // designate reg 010 for loading immediates
	  rd_addrB = {2'b10, mach_code[4:3]};
	  rd_addrA = 4'b0000;
    end else if(instr == 4'b1110) begin //move into reg B
      regfile_in = rslt;
	  rd_addrB = {2'b10, mach_code[1:0]};
	  rd_addrA = {1'b0, mach_code[4:2]};	  
      rd_addrSwitch = rd_addrB;
    end else if(instr == 4'b1010) begin //move into reg A
      regfile_in = rslt;
	  rd_addrB = {2'b10, mach_code[1:0]};
	  rd_addrA = {1'b0, mach_code[4:2]};
      rd_addrSwitch = rd_addrA;

    end else if(instr == 4'b1000) begin // load
      regfile_in = regfile_dat;
	  rd_addrB = {2'b10, mach_code[1:0]};
	  rd_addrA = {1'b0, mach_code[4:2]};
      rd_addrSwitch = rd_addrB;

    end 
  end


  alu alu1(.alu_cmd       (alu_cmd),
          .inA    (datA),
          .inB    (muxB),
          .sc_i   (sc),
          .sv     (sv),
          .sc_o   (sc_o),
          .result      (rslt),
          .zeroflg     (zeroflg),
          .sign        (sign),
          .carry       (carry),
          .overflow    (overflow));  


  dat_mem dm(.dat_in    (datA),  // from reg_file
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
      zeroQ <= zero;       
      end
    if(sc_clr)
	  sc_in <= 'b0;
    else if(sc_en)
      sc_in <= sc_o;
  end
//set done to 1 when finished
  assign done = prog_ctr == 128;
 
endmodule