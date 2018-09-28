// instantiates four deciimal units, and starts at the 0th one.
// the 0th one gets the external enable, and every other one is
// driven by the previous one.
module decimal_counter(
	output [3:0] V3,
	output [3:0] V2,
	output [3:0] V1,
	output [3:0] V0,
	output carry_out,
	input reset,
	input clock,
	input enable
);

	wire carry0, carry1, carry2;

	decimal_unit du0(
		.value(V0),
		.carry_out(carry0),
		.reset(reset),
		.clock(clock),
		.enable(enable)
	);
	
	decimal_unit du1(
		.value(V1),
		.carry_out(carry1),
		.reset(reset),
		.clock(clock),
		.enable(carry0)
	);
	
	decimal_unit du2(
		.value(V2),
		.carry_out(carry2),
		.reset(reset),
		.clock(clock),
		.enable(carry1)
	);
	
	decimal_unit du3(
		.value(V3),
		.carry_out(carry_out),
		.reset(reset),
		.clock(clock),
		.enable(carry2)
	);

endmodule
