import json

template = '''
`timescale 1ns / 1ps

module cache_sim;

	// Inputs
	reg clk;
	reg rst;
	reg [31:0] addr;
	reg load;
	reg replace;
	reg store;
	reg invalid;
	reg [2:0] u_b_h_w;
	reg [31:0] din;

	// Outputs
	wire hit;
	wire [31:0] dout;
	wire valid;
	wire dirty;
	wire [22:0] tag;

	// Instantiate the Unit Under Test (UUT)
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
		.hit(hit), 
		.dout(dout), 
		.valid(valid), 
		.dirty(dirty), 
		.tag(tag)
	);

	initial begin
		clk = 1;
		forever #0.5 clk = ~clk;
	end

	reg [31:0]counter = -1;

	always @(posedge clk) begin
		counter = counter + 32'b1;

		case (counter)
			// Initialize Inputs
			32'd0: begin
				rst <= 1;
				addr <= 0;
				load <= 0;
				replace <= 0;
				store <= 0;
				invalid <= 0;
				u_b_h_w <= 0;
				din <= 0;
			end
			
%SIM%
			default: begin
				$finish;
			end
		endcase
	end

endmodule

'''

with open('lab3.json', 'r') as f:
    config = json.load(f)
simulations = config['simulation']
text_sim = ''
for i in range(1, len(simulations) + 1):
    simulation = simulations[i - 1]
    text_sim += f'\t\t\t32\'d{i}: begin\n'
    if i == 1:
        text_sim += f'\t\t\t\trst <= 0;\n'
    load = 1 if simulation['type'] == 'load' else 0
    store = 1 if simulation['type'] == 'store' else 0
    replace = 1 if simulation['type'] == 'replace' else 0
    invalid = 1 if simulation['type'] == 'invalidate' else 0
    addr = simulation['addr']
    din = simulation.get('data_in', 0)
    if simulation['width'] == 'w':
        u_b_h_w = 2
    elif simulation['width'] == 'h':
        u_b_h_w = 1
    elif simulation['width'] == 'b':
        u_b_h_w = 0
    elif simulation['width'] == 'hu':
        u_b_h_w = 5
    elif simulation['width'] == 'bu':
        u_b_h_w = 4
    text_sim += f'\t\t\t\tload <= {load};\n\t\t\t\tstore <= {store};\n\t\t\t\treplace <= {replace};\n\t\t\t\tinvalid <= {invalid};\n\t\t\t\taddr <= 32\'h{hex(addr)[2:]};\n\t\t\t\tdin <= 32\'h{hex(din)[2:]};\n\t\t\t\tu_b_h_w <= {u_b_h_w};\n'
    text_sim += f'\t\t\tend\n\n'
with open('cache_sim.v', 'w') as f:
    f.write(template.replace('%SIM%', text_sim))
