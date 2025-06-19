module instructionmemory(
	input wire [31:0] addr,
	output wire [31:0] instrucao
);
	reg [31:0] memoria [2047:0];
	
	initial begin
		$readmemb("binarios/matrixmul.bin", memoria);
	end
	
	assign instrucao = memoria[addr[9:2]];
endmodule