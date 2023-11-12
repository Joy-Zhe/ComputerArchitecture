`timescale 1ns / 1ps

module cache_sim;

	// Inputs
	wire clk;
	wire rst;
	wire [31:0] addr;
	wire load;
	wire replace;
	wire store;
	wire invalid;
	wire [2:0] u_b_h_w;
	wire [31:0] din;

	// Outputs
	wire o_hit;
	wire [31:0] o_dout;
	wire o_valid;
	wire o_dirty;
	wire [22:0] o_tag;

    // internal
    wire[63:0] valid;
    wire[63:0] dirty;
    reg[22:0] tag[0:63];
    reg[31:0] data[0:255];

	cache uut (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.load(load),
		.replace(replace), 
		.store(store), 
		.invalid(invalid), 
		.u_b_h_w(u_b_h_w),
		.din(din), 
		.hit(o_hit), 
		.dout(o_dout), 
		.valid(o_valid), 
		.dirty(o_dirty), 
		.tag(o_tag)
	);

    // signals here
    assign valid = uut.inner_valid;
    assign dirty = uut.inner_dirty;
    integer i;
    always @* begin
        for (i = 0; i < 64; i = i + 1) begin
            tag[i] = uut.inner_tag[i];
        end
        for (i = 0; i < 256; i = i + 1) begin
            data[i] = uut.inner_data[i];
        end
    end
      
endmodule

