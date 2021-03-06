// allows for slower clocks for the decimal counter
module slow_clocks(
	output reg clock_1000ms,
	input enable,
	input reset,
	input CLOCK_50
);

	reg [27:0] counter_1000ms; // 1 second
	
	always @ (posedge CLOCK_50)
	begin
		if (reset) begin
			counter_1000ms <= 28'h0000000;
			clock_1000ms = 1'b0;
		end
		else if (counter_1000ms < 50_000_000) begin
			counter_1000ms <= counter_1000ms + 28'h0000001;
			if (enable) begin
				clock_1000ms <= 1'b1;
			end
		end
		else begin
			counter_1000ms <= 28'h0000000;
			clock_1000ms = 1'b0;
		end
	end

endmodule
