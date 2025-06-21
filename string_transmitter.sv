module string_transmitter(
	input i_Clk,
	input i_Rst,
	input i_txd_busy,
	input [7:0] i_rx_data,
	input i_rx_end,
	input i_proc_busy,
	input [31:0] i_tx_number,
	output reg [7:0] tx_data,
	output reg o_send_to_computer,
	//output reg [3:0] o_mem_index,
	output logic o_number_ready,
	output reg [31:0] o_rx_number,
	output [1:0] dbg_counter
);
	parameter CAPACIDADE_BYTES = 32; // qtd de characteres (bytes) que a placa vai armazenar na memoria no max
	
	logic endOfString;
	logic [CAPACIDADE_BYTES-1:0] buffer;
	logic [9:0] index;
	logic terminarmsg;
	assign dbg_buffer = buffer;
	reg gotIt; // usar a logica do Serial.sv original de evitar armazenar 2x o mesmo caractere
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			integer i;
			//for (i = 0; i < CAPACIDADE_BYTES; i = i+1) begin
				//buffer[i] <= 1'b0; // zerar toda a memoria em reset assincrono
			//end
			buffer <= '0;
			gotIt = 1'b0;
		end else begin
			if (i_rx_end) begin
				if (!gotIt) begin
					gotIt = 1'b1;
					//buffer[0] <= i_rx_data; // novo dado vai ser adicionado no inicio do vetor
					//buffer[CAPACIDADE_BYTES-1:1] <= buffer[CAPACIDADE_BYTES-2:0]; // e o resto vai ser shiftado pro lado
					buffer <= {buffer[23:0], i_rx_data};
				end else begin
					//buffer = buffer; // se nada foi adicionado, mantem tudo do jeito que tava
					//gotIt = gotIt;
				end
			end else begin
				gotIt = 1'b0;
				//buffer = buffer;
			end
		end
	end
	
	// bloco para selecionar qual byte da memoria vai ser enviado na sequencia
	// eventualmente talvez eu venha com algo mais compreensivel D:
	reg [1:0] counter;
	logic [1:0] delay;
	assign dbg_counter = counter;
	//reg [3:0] o_mem_index;
	logic [3:0] mem_index;
	reg state, next_state;
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			state = 1'b0;
		end
		else state <= next_state;
	end
	
	always@(*) begin
		next_state = state;
		case(state)
			1'b0: begin // recebendo os numeros
						if (mem_index == 4'd8 && !i_proc_busy) next_state = 1'b1;
						else next_state = 1'b0;
					end
			1'b1: begin // enviando o resultado
						if (mem_index == 4'd12 && !i_txd_busy) next_state = 1'b0;
						else next_state = 1'b1;
					end
		endcase
	end
	reg japegouhomi;
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			counter <= 0;
			//o_mem_index <= 0;
			mem_index <= 0;
			o_number_ready <= 0;
			japegouhomi <= 0;
			delay <= 0;
		end
		else begin
		o_number_ready <= 1'b0;
		//if (state != next_state) mem_index <= 4'd0;
		if (state == 1 && next_state == 0) mem_index <= 4'd0;
		o_send_to_computer <= 1'b0;
		case(state)
			1'b0: begin
						o_send_to_computer <= 1'b0;
						if (i_rx_end) begin
							if (!japegouhomi) begin
								japegouhomi <= 1;
								if (counter == 2'd3) begin
									o_rx_number <= {buffer[23:0], i_rx_data};
									//o_mem_index <= o_mem_index + 1'b1;
									mem_index <= mem_index + 1'b1;
									o_number_ready <= 1'b1;
								end
								counter <= counter + 1'b1;
							end else begin
								//japegouhomi <= japegouhomi;
								//counter <= counter;
							end
						end else begin
							japegouhomi <= 0;
							//counter <= counter;
						end
					end
			1'b1: begin
						if (!i_proc_busy) begin
							o_send_to_computer <= 1'b1;
							if (!i_txd_busy) begin
							case(counter)
								2'b00: tx_data <= i_tx_number[31:24]; 
								2'b01: tx_data <= i_tx_number[23:16];
								2'b10: tx_data <= i_tx_number[15:8];
								2'b11: tx_data <= i_tx_number[7:0];
							endcase
								if (counter == 2'd3) begin
									o_number_ready <= 1'b1;
									if (mem_index == 12) mem_index <= 4'b0;
									else mem_index <= mem_index + 1'b1;
								end
								counter <= counter + 1'b1;
							end
						end
					end
		endcase
		end
	end
endmodule