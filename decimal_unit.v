// decimal counter that counts to 9, then resets back to 0.
// everytime it does this, it sends a carry out, which acts as an enable
// for another decimal unit.
module decimal_unit(
	output reg [3:0] value,
	output carry_out,
	input reset,
	input clock,
	input enable
);
	
	always @ (posedge clock)
	begin
		if (reset) begin
			value <= 4'h0;
		end
		else if (enable) begin
			if (value < 4'h9) begin
				value <= value + 4'h1;
			end
			else begin
				value <= 4'h0;
			end
		end
	end
	
	assign carry_out = (value == 4'h9 && enable);
	
endmodule
