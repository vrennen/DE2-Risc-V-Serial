module datamemory(
	input wire clk,
	input wire MemRead,
	input wire MemWrite,
	input wire [31:0] address,
	input wire [31:0] writeData,
	output wire [31:0] readData
);
	reg [31:0] memory [11:0];
	
	initial begin
		$readmemb("binarios/datamemory.bin", memory);
	end
	
	assign readData = (MemRead) ? memory[address[9:2]] : 32'b0;
	
	always @(posedge clk) begin
		if (MemWrite) begin
			memory[address[9:2]] = writeData;
		end
	end
	
endmodule