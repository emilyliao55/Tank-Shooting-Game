// goes through all legal coordinates of the screen
module xycounter(
	output reg [7:0] x,
	output reg [6:0] y,
	output reg done,
	input clock,
	input enable
);

	always @ (posedge clock)
	begin
		// when enable is raised, start counting
		if (enable)
		begin
			if (x < 159)
			begin
				x <= x + 8'h01;
			end
			else
			begin
				if (y < 119)
				begin
					y <= y + 7'h01;
					x <= 8'h00;
				end
			end
			done <= (x == 159 && y == 119);
		end
		else
		begin
			x <= 8'h00;
			y <= 7'h00;
			done <= 1'b0;
		end
	end

endmodule
