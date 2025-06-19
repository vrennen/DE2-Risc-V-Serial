`include "Control.v"
`include "ALUControl.v"
`include "Mem_Model.v"
`include "REG_FILE.v"

module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM - dado no testbench determinado pelo sram que lê o arquivo de soma5.bin e repassa para o resto do processador
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,

	
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT,      // equal RF_WD this port is used for test
	
	input wire i_dbg_run
	);


	initial begin
		NUM_INST <= 0;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (~RSTn | HALT) NUM_INST <= 0;
		else if (RSTn && i_dbg_run) NUM_INST <= NUM_INST + 1;
	end

	// TODO: implement
	wire [6:0] ALUOp;
	wire [2:0] Concat_control;
	wire [3:0] BE;
	Control control(   /// supostamente instanciado certo pelo criador
		.opcode(I_MEM_DI[6:0]), // input vem do tb
		.funct3(I_MEM_DI[14:12]), // vem do tb
   		.RegDst(RegDst),       //output
   		// .Jump(Jump),
		// .Branch(Branch),
   		//.MemRead(MemRead), // no need
   		.MemtoReg(MemtoReg),
   		.ALUOp(ALUOp),
   		.MemWrite(MemWrite), // MemWrite não definido isso era para estar assim?
   		.ALUSrc1(ALUSrc1),
		.ALUSrc2(ALUSrc2),
   		.RegWrite(RegWrite),
		// .JALorJALR(JALorJALR),
		.BE(BE),
		.Concat_control(Concat_control)
   		);

	wire [4:0] ALU_operation;
	ALUControl alucontrol(
		.ALUOp(ALUOp),   // input
 		.funct3(I_MEM_DI[14:12]),
		.funct7(I_MEM_DI[31:25]),
		.ALU_operation(ALU_operation) // output
   		);
	
	wire [31:0] offset;
	Immediate_Concatenator Im_con(
		.Instr(I_MEM_DI),     //input
		.Concat_control(Concat_control), 
		.offset(offset)   //output
		);

	//Instruction Memory Output
	// wire [31:0] JAL_Address;
	// wire [31:0] JALR_Address;
	// wire [31:0] Branch_Target;
	reg [31:0] PC; //Registro do PC atual
	wire [31:0] NXT_PC; // valor do proximo PC
	// wire Branch_Taken;
	
	//instantiate ALU module
	wire [31:0] ALU_Result;
	ALU alu(
		.Operand1( (ALUSrc1) ? PC : RF_RD1),    //input
		.Operand2( (ALUSrc2) ? offset : RF_RD2 ), 
		.ALU_operation(ALU_operation), 
		.Zero(Zero),    //output
		.ALU_Result(ALU_Result)  
		);


	//PC update - Atualização do PC ou Fetch
	// assign JAL_Address = ALU_Result; // Jump and Link é atualizado para o resultado da ALU pulando para o local especificado
	// assign JALR_Address = ALU_Result & (32'hfffffffe); // Faz uma operação similar ao jump and link mas o jalr é implementado para que o endereço tenha o binario menos significativo como zero e o processador saber que é essa operação
	// assign Branch_Target = offset + PC; // PC atual com saido do concatenador immediato (Que recebe Instruções de I_MEM_DI e o controlador do concatenador, detrminado no controle do processador)
	// assign Branch_Taken = Branch & Zero; //Recebe do controle e da alu
	// assign NXT_PC = (~RSTn)? 0 : (Jump)? ( (JALorJALR)? JALR_Address : JAL_Address ) : ((Branch_Taken)? Branch_Target : PC+4 );// Reset do Testbench (esse que é especificado em RISCV_CLKRST), Jump vem do controle, JAL or JALR vem do controle, JAL_Adress e JALR_Adress determinados em cima, Branch Taken e Branch targer em cima tbm PC é um registrador desse modulo
	// assign NXT_PC = (~RSTn)? 0 : ((Branch_Taken)? Branch_Target : PC+4 );
	assign NXT_PC = (~RSTn)? 0 : (PC+4);
	always @(posedge CLK or negedge RSTn) begin //PC é determinado na subida do clock
		if (!RSTn) begin
			PC <= 0;
		end else begin
			if (i_dbg_run) begin
				PC <= NXT_PC;// PC começa em zero e vai recebendo os valores de NXT+PC
				I_MEM_ADDR <= NXT_PC[11:0]; // nxt_pc determina I_MEM_ADDR
			end
		end
	end
	//assign I_MEM_ADDR = PC[11:0];
	assign I_MEM_CSN = (~RSTn)? 1'b1 : 1'b0; //Chip Select Negative é determinado pelo inverso do reset ativa e desativa o acesso a memoria de instruções


	//Data Memory Output
	wire [31:0] temp_ALU_Result = ALU_Result;

	assign D_MEM_CSN = (~RSTn)? 1'b1 : 1'b0;
	assign D_MEM_DOUT = RF_RD2;
	assign D_MEM_ADDR = temp_ALU_Result[13:2]; 
	assign D_MEM_WEN = ~MemWrite;
	assign D_MEM_BE = BE;

	//Register File Output
	assign RF_WE = RegWrite;
	assign RF_RA1 = I_MEM_DI[19:15];
	assign RF_RA2 = I_MEM_DI[24:20];
	assign RF_WA1 = (RegDst) ? I_MEM_DI[11:7] : I_MEM_DI[24:20];
	// assign RF_WD = (Jump) ? PC+4 : (MemtoReg) ? D_MEM_DI : ALU_Result;
	assign RF_WD = (MemtoReg) ? D_MEM_DI : ALU_Result;


	//Check two sequence of instructions for HALT
	//assign HALT = (RF_RD1 == 32'h0000000c) || (I_MEM_DI == 32'h00008067);	
	assign HALT = (I_MEM_DI == 32'b00000000000000000000000000000000);
	
	// assign OUTPUT_PORT = (Branch) ? Branch_Taken : (MemWrite)? ALU_Result : RF_WD;
	assign OUTPUT_PORT = (MemWrite)? ALU_Result : RF_WD;

endmodule





module Immediate_Concatenator (
	input wire [31:0] Instr,
	input wire [2:0] Concat_control,
	output reg [31:0] offset
	);
	reg signed [31:0] signed_offset;

	always@(*) begin
		case(Concat_control)

			3'b001 : begin //LUI, AUIPC, U-type 7'b0110111, 7'b0010111
				signed_offset = {Instr[31:12],12'b0};
				offset = signed_offset;
			end

		/*
			3'b010 : begin //JAL , J-type 7'b1101111
				signed_offset = {Instr[31],Instr[19:12], Instr[20], Instr[30:21],12'b0};
				offset = signed_offset >>>11;
			end

		*/
			3'b011 : begin //(JALR), Load, I-type 7'b1100111, 7'b0000011, 7'b0010011
				signed_offset = {Instr[31:20],20'b0};
				offset = signed_offset >>>20;
			end
		/*
			3'b100 : begin //Branch, B-type 7'b1100011
				signed_offset = {Instr[31],Instr[7],Instr[30:25],Instr[11:8],20'b0};
				offset = signed_offset >>>19;
			end
		*/
			3'b101 : begin //Store, S-type 7'b0100011
				signed_offset = {Instr[31:25],Instr[11:7],20'b0};
				offset = signed_offset >>>20;
			end
			3'b110 : begin // SLLI, SRLI, SRAI
				offset = {27'b0,Instr[24:20]} ;
			end
			default : offset = 0;

		endcase
	end

endmodule

module ALU(
	input wire [31:0] Operand1,
	input wire [31:0] Operand2,
	input wire [4:0] ALU_operation,
	output reg Zero,
	output reg [31:0] ALU_Result
	);
	
	reg signed [31:0] signed_Operand1;
	reg signed [31:0] signed_Operand2;
	always@(*) begin
		case(ALU_operation)
			5'b00000: begin    // signed Add  (/ AUIPC)
				signed_Operand1 = Operand1; 
				signed_Operand2 = Operand2; 
				ALU_Result = signed_Operand1 + signed_Operand2; 
				Zero = 1'b0;
			end
			5'b00001: begin // signed Sub
				signed_Operand1 = Operand1; 
				signed_Operand2 = Operand2; 
				ALU_Result = signed_Operand1 - signed_Operand2; 
				Zero = 1'b0;
			end
			5'b00010: begin
				ALU_Result = Operand1 & Operand2; 
				Zero = 1'b0;
			end
			5'b00011: begin
				ALU_Result = Operand1 | Operand2; 
				Zero = 1'b0;
			end
			5'b00100: begin
				ALU_Result = ~(Operand1 & Operand2); 
				Zero = 1'b0;
			end
			5'b00101: begin 
				ALU_Result = ~(Operand1 | Operand2); 
				Zero = 1'b0;
			end
			5'b00110: begin 
				ALU_Result = Operand1 ^ Operand2; 
				Zero = 1'b0;
			end
			5'b00111: begin
				ALU_Result = Operand1 ~^ Operand2; 
				Zero = 1'b0;
			end
			5'b01000: begin
				ALU_Result = Operand2; 
				Zero = 1'b0;
			end
			5'b01001: begin
				ALU_Result = ~Operand2; 
				Zero = 1'b0;
			end
			5'b01010: begin
				ALU_Result = Operand1>>Operand2; 
				Zero = 1'b0;
			end
			5'b01011: begin
				signed_Operand1 = Operand1; 
				ALU_Result = signed_Operand1>>>Operand2; 
				Zero = 1'b0;
			end

			5'b01100: begin
				ALU_Result = Operand1 + Operand2; 
				Zero = 1'b0; // Unsigned Add
			end

			5'b01101: begin
				ALU_Result = Operand1<<Operand2; 
				Zero = 1'b0;
			end
			5'b01110: begin 
				ALU_Result = Operand1<<<Operand2; 
				Zero = 1'b0;
			end
		
			5'b01111: begin
				ALU_Result = Operand1 - Operand2; 
				Zero = 1'b0; // Unsigned Sub
			end

			/*

			5'b10000: begin
				ALU_Result = (Operand1 == Operand2); 
				Zero = (Operand1 == Operand2); // BEQ
			end
			5'b10001: begin
				ALU_Result = (Operand1 != Operand2); 
				Zero = (Operand1 != Operand2); // BNE
			end
			5'b10010: begin
				   // BLT
				signed_Operand1 = Operand1; 
				signed_Operand2 = Operand2; 
				ALU_Result = (signed_Operand1 < signed_Operand2);
				Zero = (signed_Operand1 < signed_Operand2);
			end
			5'b10011: begin
				  // BGE
				signed_Operand1 = Operand1; 
				signed_Operand2 = Operand2; 
				ALU_Result = (signed_Operand1 >= signed_Operand2);
				Zero = (signed_Operand1 >= signed_Operand2);
			end
			5'b10100: begin
				ALU_Result = (Operand1 < Operand2);
				Zero = (Operand1 < Operand2); //BLTU
			end
			5'b10101: begin
				ALU_Result = (Operand1 >= Operand2);
				Zero = (Operand1 >= Operand2); //BGEU
			end
			*/
			5'b10110:begin   // SLTI, SLT
				signed_Operand1 = Operand1; 
				signed_Operand2 = Operand2; 
				ALU_Result = (signed_Operand1 < signed_Operand2);
				Zero = 0; 
			end
			5'b10111: begin
				ALU_Result = (Operand1 < Operand2);
				Zero = 0; //SLTIU , SLTU
			end
			default: begin
				signed_Operand1 = Operand1; 
				signed_Operand2 = Operand2; 
				ALU_Result = signed_Operand1 + signed_Operand2; 
				Zero = 1'b0;
			end
		endcase

	end
	

endmodule
