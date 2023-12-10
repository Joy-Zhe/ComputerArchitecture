module RAM_B (
	input wire clk,
	input wire rst,
	input wire cs,
	input wire we,
	input wire [31:0] addr,
	input wire [31:0] din,
	output wire [31:0] dout,
	output wire stall,
	output reg ack
	);
	
	parameter
		ADDR_WIDTH = 11;

	localparam
		S_IDLE = 0,
		S_READ = 1,
		S_WRITE = 2;
	
	reg [31:0] data [0:(1<<ADDR_WIDTH)-1];
	
	integer i = 0;
	initial	begin
		for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
			data[i] = 32'b0;
		end
		$readmemh("ram.hex", data);
	end

	reg [2:0]state = 0;
	reg [31:0] out = 0;
	assign ram_state = state;

	reg [2:0]next_state = 0;

	always @ (posedge clk) begin
		if (rst) begin
			state = S_IDLE;
		end
		else begin
			if (state == S_WRITE) begin
				data[addr[ADDR_WIDTH+1:2]] <= din;
			end
			state <= next_state;
		end
	end

	always @ (*) begin
		if (cs) begin
			if (we) begin
				if(state == S_IDLE)
					next_state = S_WRITE;
				else if (state == S_WRITE)
					next_state = S_IDLE;
				else
					next_state = 3'bxxx;
			end
			else begin
				if (state == S_IDLE)
					next_state = S_READ;
				else if (state == S_READ)
					next_state = S_IDLE;
				else
					next_state = 3'bxxx;
			end
		end
		else begin
			next_state = S_IDLE;
		end
	end

	always @ (*) begin
		if (state != S_READ && state != S_WRITE) begin
			ack = 0;
			out = 0;
		end

		else if (state == S_READ) begin
			ack = 1;
			out = data[addr[ADDR_WIDTH+1:2]];
		end

		else if (state == S_WRITE) begin
			ack = 1;
			out = 0;
		end

		else begin
			ack = 0;
			out = 0;
		end
	end

	assign dout = out;
	assign stall = cs & ~ack;
	
endmodule
