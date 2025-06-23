`include "risc-v/RISCV_TOP.v"
//`include "risc-v/datamemory.v"
//`include "risc-v/instructionmemory.v"
module riscv_casca(
	input i_Clk,
	input i_Rstn,
	input [31:0] i_mem_input,
	//input [3:0]  i_mem_index,
	input i_number_ready,
	output logic [31:0] o_mem_output,
	output logic o_proc_busy,
	output logic dbg_HALT,
	output logic [1:0] dbg_risc_state,
	output logic [31:0] dbg_instruct,
	output logic [31:0] dbg_PC,
	input [9:0] dbg_mem_addr,
	output wire [31:0] dbg_dump,
	output wire [3:0] dbg_mem_index,
	input dbg_manual_clock,
	output dbg_assert_pc
);

  // Sinais de sai­da
  wire I_MEM_CSN;
  wire [31:0] I_MEM_DI;
  wire [13:0] I_MEM_ADDR;
  wire D_MEM_CSN;
  wire [31:0] D_MEM_DI;
  wire [31:0] D_MEM_DOUT;
  wire [11:0] D_MEM_ADDR;
  wire D_MEM_WEN;
  wire [3:0] D_MEM_BE;
  wire RF_WE;
  wire [4:0] RF_RA1;
  wire [4:0] RF_RA2;
  wire [4:0] RF_WA1;
  wire [31:0] RF_RD1;
  wire [31:0] RF_RD2;
  wire [31:0] RF_WD;
  wire HALT;
  wire [31:0] NUM_INST;
  wire [31:0] OUTPUT_PORT;
  wire [31:0] DOUT;
 
  assign dbg_instruct = DOUT;
  assign dbg_HALT = HALT;
  
  logic [1:0] clockcounter;
  logic dbg_clockreduzido;
  
  always@(posedge i_Clk) begin
		clockcounter <= clockcounter+1;
  end
  assign dbg_clockreduzido = clockcounter[1];
  
  // Instanciando o processador
  RISCV_TOP riscv_top (
      .CLK(dbg_clockreduzido), // fazer o processador rodar apos receber as matrizes
      .RSTn(i_Rstn),            // reset negative
      .I_MEM_CSN(I_MEM_CSN),
      .I_MEM_DI(DOUT), //tava ligado em I_MEM_DI
      .I_MEM_ADDR(I_MEM_ADDR),
      .D_MEM_CSN(D_MEM_CSN),
      .D_MEM_DI(D_MEM_DI),
      .D_MEM_DOUT(D_MEM_DOUT),
      .D_MEM_ADDR(D_MEM_ADDR),
      .D_MEM_WEN(D_MEM_WEN),
      .D_MEM_BE(D_MEM_BE),
      .RF_WE(RF_WE),
      .RF_RA1(RF_RA1),
      .RF_RA2(RF_RA2),
      .RF_WA1(RF_WA1),
      .RF_RD1(RF_RD1),
      .RF_RD2(RF_RD2),
      .RF_WD(RF_WD),
      .HALT(HALT),
      .NUM_INST(NUM_INST),
      .OUTPUT_PORT(OUTPUT_PORT),
		.i_dbg_run(risc_v_on),
		.dbg_PC(dbg_PC),
		.dbg_assert_pc(dbg_assert_pc)
  );
 
  // Instanciando o mÃ³dulo de memÃ³ria de instrucao
  SP_SRAM #(.ROMDATA("binarios/matrixmul_addshiftsltsub.bin"), .AWIDTH(12), .SIZE(2048)) inst_mem (
      .CLK(dbg_clockreduzido), // CLK do tb especificado em RISCV_CLKRST
      .CSN(0), // Inverso do Reset
      .ADDR(I_MEM_ADDR[13:2]), // Recebe o valor de NEXT_PC
      .WEN(1'b1), // Tem de estar ativo para nÃ£o usar a entrada de DI
      .BE(4'b1111), // permite que todos os 4 bytes sejam lidos na sram
      .DI(), // SÃ³ recebe algo na memoria de dados
      .DOUT(DOUT), // A memÃ³ria de programa fornece as instruÃ§Ãµes para o processador e Ã© a fonte de meu problema
		.i_dbg_run(risc_v_on),
		.dbg_addr(),
		.dbg_dump()
  );
	//assign dbg_PC = DOUT;
  // Instanciando o mÃ³dulo de memÃ³ria de dados
  /*
  SP_SRAM #(.ROMDATA("binarios/datamemory.bin"), .AWIDTH(11), .SIZE(1024)) data_mem (
      .CLK(i_Clk),			// clock
      .CSN(final_csn),     // reset async???
      .ADDR(mem_addr),     // mem addr          (!)
      .WEN(write_enable_neg),  // write enable neg  (!)
      .BE(byte_enable),    // [3:0] byte enable (!)
      .DI(mem_input),      // data input        (!)
      .DOUT(mem_output),    // data output       (!)
		.i_dbg_run(risc_v_on),
		.dbg_addr(dbg_mem_addr),
		.dbg_dump(dbg_dump)
  );
  */
  /*rom inst_mem(
	.clock(i_Clk),
	.address(I_MEM_ADDR[12:2]),
	.q(DOUT)
  );*/
  ram data_mem(
	.clock(i_Clk),
	.address(mem_addr),
	.data(mem_input),
	.wren(~write_enable_neg),
	.byteena(byte_enable),
	.q(mem_output)
  );

  // AtribuiÃ§Ã£o de D_MEM_DI para ser igual a DOUT da memÃ³ria de	 programa
  //assign D_MEM_DI = //DOUT;

  // Instanciando o modulo de banco de registradores
  REG_FILE reg_file (
      .CLK(dbg_clockreduzido),
      .WE(RF_WE),
      .RSTn(i_Rstn),
      .RA1(RF_RA1),
      .RA2(RF_RA2),
      .WA(RF_WA1),
      .WD(RF_WD),
      .RD1(RF_RD1),
      .RD2(RF_RD2),
		.i_dbg_run(risc_v_on),
		.i_dbg_addr(dbg_mem_addr[4:0]),
		.o_dbg_reg(dbg_dump)
  );
  
  //logic [3:0] delayed_mem_index;
  //always@(posedge i_Clk) delayed_mem_index <= i_mem_index;
  
  logic [3:0] mem_index;
  always@(posedge i_Clk or negedge i_Rstn) begin 
    if (!i_Rstn) mem_index <= 4'd0;
	 else begin 
		if (i_number_ready) begin
			mem_index <= mem_index+1;
		end else if (mem_index == 12) begin
			mem_index <= 4'd0;
		end
	 end
  end
  
  logic [1:0] estado_risc, prox_estado;
  // transicao
  always@(posedge i_Clk or negedge i_Rstn) begin
	 if (!i_Rstn) begin
		estado_risc <= 2'b00;
	 end
	 else estado_risc <= prox_estado;
  end
  
  always@(*) begin // logica de transicao
    if (!i_Rstn) prox_estado = 2'b00;
	 else begin
	 prox_estado = estado_risc;
	 case(estado_risc)
		2'b00: begin // IDLE
					if (mem_index == 8) begin
						prox_estado = 2'b01;
					end
				 end
		2'b01: begin // START RISC_V
					if (HALT/*NUM_INST > 2004*/) begin               // cabou de executar, po mandar os resultados
						prox_estado = 2'b10;
					end
			    end
		2'b10: begin // END RISC_V AND SEND BACK
					if (mem_index == 12) begin
						prox_estado = 2'b00;
					end
				 end
	 endcase
	 end
  end
  
  assign D_MEM_DI = (estado_risc == 2'b01) ? mem_output : 32'b0;
  assign o_mem_output = (estado_risc == 2'b10) ? mem_output : 32'b0;
  assign final_csn = (estado_risc == 2'b01) ? D_MEM_CSN: 1'b0;
  
  logic risc_v_on;
  logic [31:0] mem_input, mem_output;
  logic [3:0] byte_enable;
  logic write_enable_neg;
  logic [3:0] mem_addr;
  logic final_csn;
  assign o_proc_busy = risc_v_on;
  always@(*) begin // logica de funcionamento
	 write_enable_neg = 1'b1;
    case(estado_risc)
		2'b00: begin // IDLE
					risc_v_on = 1'b0;
					mem_input = i_mem_input; // receber na memoria os dados da placa
					byte_enable = 4'b1111;
					write_enable_neg = ~i_number_ready;     // 0: escrever na memoria do risc
					mem_addr = mem_index;
				 end
		2'b01: begin // START RISC_V
					risc_v_on = 1'b1;
					mem_input = D_MEM_DOUT;   // ao executar o processador, deixar que ele mexa com a memoria
					//mem_output = D_MEM_DI;
					//D_MEM_DI = mem_output;
					byte_enable = D_MEM_BE;
					write_enable_neg = D_MEM_WEN;
					mem_addr = D_MEM_ADDR;
			    end
		2'b10: begin // END RISC_V AND SEND BACK
					risc_v_on = 1'b0;
					mem_input = 32'b0;
					//o_mem_output = mem_output; // enviar para a placa os dados da memoria
					byte_enable = 4'b0000;
					write_enable_neg = 1'b1;       // 1: deixar de escrever
					mem_addr = mem_index;
				 end
	 endcase
	end
	assign dbg_risc_state = estado_risc;
	assign dbg_mem_index = mem_index;
endmodule