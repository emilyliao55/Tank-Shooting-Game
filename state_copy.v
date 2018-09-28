// uses xycounter module to copy between two pieces of memory
// serves as the connections between the initial game state, current game state, and what's being displayed
module state_copy(
	output [14:0] address,
	input [2:0] color_in,
	output [7:0] x,
	output [6:0] y,
    output [2:0] color_out,
    output plot,
    output done,
	input clock,
	input enable // when enable is high, it issues addresses on the address output based on what the xycounter gives it
);

	reg [7:0] x_d;
	reg [7:0] x_d2;
	reg [6:0] y_d;
	reg [6:0] y_d2;
	reg enable_d, enable_d2;
	reg done_d, done_d2;
	assign x = x_d;
	assign y = y_d;
	assign plot = done_d ? 1'b0 : enable_d;
	assign done = done_d; // need to work out the pattern
//	assign x = x_d2;
//	assign y = y_d2;
//	assign plot = enable_d2;
	assign color_out = color_in;
	
	always @ (posedge clock)
	begin
		x_d <= inner_x;
		y_d <= inner_y;
		x_d2 <= x_d;
		y_d2 <= y_d;
		enable_d <= enable;
		enable_d2 <= enable_d;
		done_d <= inner_done;
		done_d2 <= done_d;
	end

	wire [7:0] inner_x;
	wire [6:0] inner_y;
	assign address[14:7] = inner_x;
	assign address[6:0] = inner_y;
	wire inner_done;

	xycounter xyc(
		.x(inner_x),
		.y(inner_y),
		.done(inner_done),
		.clock(clock),
		.enable(enable)
	);

endmodule
