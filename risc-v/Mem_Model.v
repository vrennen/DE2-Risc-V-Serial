module SP_SRAM #(parameter ROMDATA = "", AWIDTH = 12, SIZE = 4096) (
	input	wire			CLK,
	input	wire			CSN,//chip select negative??
	input	wire	[AWIDTH-1:0]	ADDR,
	input	wire			WEN,//write enable negative??
	input	wire	[3:0]		BE,//byte enable
	input	wire	[31:0]		DI, //data in
	output	wire	[31:0]		DOUT, // data out
	input wire  i_dbg_run,
	input  wire [9:0] dbg_addr,
	output wire [31:0] dbg_dump
);

	reg		[31:0]		ram[0 : SIZE-1];
	assign dbg_dump = ram[dbg_addr];

	initial begin
		//if (ROMDATA != "")
		$readmemb(ROMDATA, ram);
	end

	always @ (posedge CLK) begin //Determinado na subida do clock
		// Synchronous write
		if (~CSN && ~WEN) begin
			if (BE[0]) ram[ADDR][7:0] = DI[7:0];
			if (BE[1]) ram[ADDR][15:8] = DI[15:8];
			if (BE[2]) ram[ADDR][23:16] = DI[23:16];
			if (BE[3]) ram[ADDR][31:24] = DI[31:24];
		end
	end
 
	always @ (posedge CLK) begin
		// Asynchronous read
		if (~CSN && WEN) begin
			DOUT = ram[ADDR];
		end
	end
 
	//assign outline = (WEN) ? ram[ADDR] : 32'b0;
endmodule
