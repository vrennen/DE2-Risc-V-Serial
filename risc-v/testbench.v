`include "RISCV_TOP.v"
`timescale 1ns / 10ps

module testbench;

  // Sinais de entrada
  wire CLK;
  wire RSTn;

  // Sinais de saída
  wire I_MEM_CSN;
  wire [31:0] I_MEM_DI;
  wire [11:0] I_MEM_ADDR;
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

  // Instanciando o processador
  RISCV_TOP riscv_top (
      .CLK(CLK),
      .RSTn(RSTn),
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
      .OUTPUT_PORT(OUTPUT_PORT)
  );

  // Instanciando o módulo de memória de instrucao
  SP_SRAM #(.ROMDATA("transposta.bin")) inst_mem (
      .CLK(CLK), // CLK do tb especificado em RISCV_CLKRST
      .CSN(I_MEM_CSN), // Inverso do Reset
      .ADDR({2'b00,I_MEM_ADDR[11:2]}), // Recebe o valor de NEXT_PC
      .WEN(1'b1), // Tem de estar ativo para não usar a entrada de DI
      .BE(4'b1111), // permite que todos os 4 bytes sejam lidos na sram
      .DI(), // Só recebe algo na memoria de dados
      .DOUT(DOUT) // A memória de programa fornece as instruções para o processador e é a fonte de meu problema
  );
  
  // Instanciando o módulo de memória de dados
  SP_SRAM #(.ROMDATA("transpostaData.bin")) data_mem (
      .CLK(CLK),
      .CSN(D_MEM_CSN),
      .ADDR(D_MEM_ADDR),
      .WEN(D_MEM_WEN),
      .BE(D_MEM_BE),
      .DI(RF_RD2),
      .DOUT(D_MEM_DI) // A memória de programa fornece as instruções para o processador
  );

  // Atribuição de D_MEM_DI para ser igual a DOUT da memória de programa
  //assign D_MEM_DI = //DOUT;

  // Instanciando o módulo de banco de registradores
  REG_FILE reg_file (
      .CLK(CLK),
      .WE(RF_WE),
      .RSTn(RSTn),
      .RA1(RF_RA1),
      .RA2(RF_RA2),
      .WA(RF_WA1),
      .WD(RF_WD),
      .RD1(RF_RD1),
      .RD2(RF_RD2)
  );
  integer i;

  // Geração do clock (não modificar)
  reg clock_q;
  reg reset_n_q;

  initial
    begin
      // Geração do clock
      clock_q <= 1'b0;
      reset_n_q <= 1'b0;
      #101 reset_n_q <= 1'b1;
      #1000 $finish();
    end

  always begin
      #5 clock_q <= ~clock_q;
  end
  // Atribuições para sinais CLK e RSTn
  /*always @ (posedge clock_q) begin
    CLK <= clock_q;
    //RSTn <= reset_n_q;
  end*/
  assign CLK = clock_q;
  assign RSTn = reset_n_q;
  // Inicialização e carregamento do código em hexadecimal
  initial begin
    // Inicializando o clock e reset
    //CLK = 0;
    //RSTn = 0;
    //#10;
    //RSTn = 1;  // Reset desativado após 10ns

    $dumpfile("testbench.vcd");
    $dumpvars(0, testbench);

    // preciso incluir a linha que segue para também
        // monitorar os registradores internos do regfile    
        for (i = 0; i < 32; i = i + 1) begin
            $dumpvars(1, testbench.reg_file.RF[i]); // Monitora cada registrador
        end

         // preciso incluir a linha que segue para também
        // monitorar os registradores internos do regfile    
        for (i = 0; i < 32; i = i + 1) begin
            $dumpvars(1, testbench.inst_mem.ram[i]); // Monitora cada registrador
        end
/*
    // Esperar até que o HALT seja acionado
    // pesquisar. Dá pra colocar um @(posedge HALT) aqui ao invés do while
    // verifica se é possivel esperar pelo evento dentro do initial. acho que dá.
    while (!HALT) begin
      #10;
    end

    // Verificar se o programa foi executado corretamente
    // Checar a saída, número de instruções executadas e outros sinais conforme necessário
    $display("Programa Executado com Sucesso!");
    $display("Numero de Instrucoes Executadas: %d", NUM_INST);
    $display("Saida do Processador: 0x%h", OUTPUT_PORT);
    $finish;*/
  end

  initial begin
    #105; // Após reset
    $display("\nConteúdo REAL da memória de dados:");
    for (integer i = 0; i < 4; i++) begin
        $display("Endereço %0d: %h", i, data_mem.ram[i]);
    end
end

endmodule
