module Serial(
  input i_Clk,                        // clock do sistema
  input i_Rst_n,                      // reset do sistema
  input i_UART_RXD,                   // pino seria de recepcao (do computador para a placa)
  input i_send_data_to_host_computer, // iniciar a transmissao para o computador
  input [7:0] i_send_data,            // byte a enviar para o computador
  output [7:0] o_received_data,       // byte recebido do computador
  output o_data_ready,                // pino de fim de byte recebido
  output o_UART_TXD,                  // pino serial de transmissao (da placa pro computador)
  output reg o_busy                   // indicador de que a linha de transmissao esta ocupada
  );
  // PARAMETRIZATION ---------------------------------------------------------
    
  parameter CLOCK_FREQUENCY = 50000000; // 50 MHz
  parameter BAUD = 115200;
  
  // RECEIVER ----------------------------------------------------------------
  async_receiver #( .ClkFrequency(CLOCK_FREQUENCY), .Baud(BAUD) ) ar(
    .clk(i_Clk),                   // clock
    .RxD(i_UART_RXD),              // corresponde ao pino em que o dato chega serializado.
    .RxD_data_ready(o_data_ready), // sinal que sobe quando o dado esta pronto
    .RxD_data(o_received_data),    // dado recebido serializado
    .RxD_endofpacket(),            // sinal que sobe quando a linha fica em standby
    .RxD_idle()                    //pino existente mas nao usado neste exemplo.
  );
  
  // TRANSMITTER -------------------------------------------------------------
  async_transmitter #( .ClkFrequency(CLOCK_FREQUENCY), .Baud(BAUD) ) serializer(
    .clk(i_Clk),                              // clock de entrada.
    .TxD(o_UART_TXD),                         // esse eh o pino serial, que carregara os dados de TxD_data serializados
    .TxD_start(i_send_data_to_host_computer), // indica que pode comecar a transmitir os dados de TxD_data
	 .TxD_data(i_send_data),                   // input temporario de handshake
    .TxD_busy(o_busy)                         // toda transmissao deve aguardar esse pino estar em zero pra transmitir. eh um pino de saida do modulo
  );
endmodule

