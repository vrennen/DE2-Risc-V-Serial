module casca(
	input CLOCK_50,
	input [3:0] KEY,
	input [9:0] SW,
	input UART_RXD,
	output UART_TXD,
	//output [17:0] LEDR,
	output [1:0] LEDG,
	
	// os leds e os displays de 7 segmentos nao estao sendo usados, mas manter aqui caso sejam necessarioss
	output [17:0] LEDR, // vai apresentar a quantidade de dados recebidos do computador
	// nesse exemplo, cada par de displays vai apresentar o hexadecimal do caractere recebido.
	// a cada novo caractere, os anteriores sao shiftados para a esquerda.
	output [6:0] HEX0, 
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7 
);
  wire ocupado;
  wire send_computer;
  wire [7:0] send_char;
  wire [7:0] received_char;
  wire rx_end;
  wire number_ready;
  
  string_transmitter transmissao(
	 .i_Clk(CLOCK_50),
	 .i_Rst(KEY[0]),
	 .i_txd_busy(ocupado),
	 .i_rx_data(received_char),
	 .i_rx_end(rx_end),
	 .i_proc_busy(proc_busy),
	 .i_tx_number(mem_output),
	 .tx_data(send_char),
	 .o_send_to_computer(send_computer),
	 //.o_mem_index(mem_index),
	 .o_number_ready(number_ready),
	 .o_rx_number(mem_input),
	 .dbg_counter(LEDG)
	 );
  
  Serial echo(
    .i_Clk(CLOCK_50),
    .i_Rst_n(KEY[0]),
    .i_UART_RXD(UART_RXD),
	 .i_send_data_to_host_computer(send_computer),
	 .i_send_data(send_char),
	 .o_received_data(received_char),
	 .o_data_ready(rx_end),
    .o_UART_TXD(UART_TXD),
	 .o_busy(ocupado)
  );
  wire [31:0] mem_input, mem_output;
  wire [3:0] mem_index;
  wire proc_busy;
  wire haltou;
  wire [2:0] estado_risc;
  wire [31:0] number;
  wire [31:0] dbg_PC;
  wire [31:0] dbg_mem_out;
  riscv_casca processador(
	 .i_Clk(CLOCK_50),
	 .i_Rstn(KEY[0]),
	 .i_mem_input(mem_input),
	 //.i_mem_index(mem_index),
	 .i_number_ready(number_ready),
	 .o_mem_output(mem_output),
	 .o_proc_busy(proc_busy),
	 .dbg_HALT(haltou),
	 .dbg_risc_state(estado_risc),
	 .dbg_instruct(number),
	 .dbg_PC(dbg_PC),
	 .dbg_mem_addr(SW[9:0]),
	 .dbg_dump(dbg_mem_out),
	 .dbg_mem_index(mem_index),
	 .dbg_manual_clock(~KEY[3]),
  );
  

  assign LEDR[3:0] = mem_index;
  assign LEDR[17] = proc_busy;
  assign LEDR[16] = haltou;
  assign LEDR[15] = KEY[0];
  assign LEDR[14] = ~KEY[3];
  assign LEDR[13:12] = estado_risc;
  assign LEDR[11:4] = dbg_PC[7:0];
  SEG7_LUT_8 sl_1(	HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7,dbg_mem_out);

endmodule 