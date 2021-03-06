module TankShooter // change this to project name accordingly
	(
	PS2_CLK, // change to PS2_KBCLK (depending on assignment pins)
	PS2_DAT, // change to PS2_KBDAT
	
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5,
		HEX6,
		HEX7,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,					//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
		,LEDR
		,LEDG
	);

inout				PS2_CLK;
inout				PS2_DAT;

	output reg [17:0] LEDR;
//	assign LEDR[13:7] = base_x;
//	assign LEDR[6:0] = base_y;
	output reg [7:0] LEDG;
//	assign LEDG[4:0] = state;

	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	output [6:0] HEX6;
	output [6:0] HEX7;
	
	
	input			CLOCK_50;				//	50 MHz
	//input   [9:0]   SW;
	input [17:0] SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK;			//	VGA BLANK
	output			VGA_SYNC;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	//assign resetn = KEY[0];
	assign resetn = SW[17];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
//	reg [2:0] colour;
//	reg [7:0] x;
//	reg [6:0] y;
//	reg writeEn;
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
	// "diagram" of how the game works:
	// GAME CORE <---> GAME STATE ---> STATE COPY ---> VGA
	// game core represents the main information of the game (x and y variables, colours, positions, etc.)
	// game state is a piece of memory that stores the current state of the game
	// state copy copies the contents of the game state to the VGA
	// VGA displays the game on screen

	// core variables represent the connections between game core and game state
	wire [14:0] core_address;
	reg [7:0] core_x;
	reg [6:0] core_y;
	assign core_address = {core_x, core_y};
	reg [2:0] core_colour;
	reg core_wren;
	wire [2:0] core_q; // read back from game state to game core
	wire [14:0] copy_address; // address state copy uses to read from game state
	wire [2:0] copy_q; // read back from game state to state copy
	
	// 2 port memory that stores the state of the game
	// 1 side is where the core of the game writes to, and reads back
	// other side where the game reads from
	game_state_t2p gs(
		.address_a(core_address),
		.address_b(copy_address),
		.clock(clock),
		.data_a(core_colour),
		.data_b(3'b000),
		.wren_a(core_wren),
		.wren_b(1'b0),
		.q_a(core_q),
		.q_b(copy_q)
	);
	
	assign colour = copy_q;
	wire copy_done;
	reg copy_enable;
	
	// reads from the b port of the game state, and writes to VGA
	// a copy sequence is started when the main game does to SLEEP
	state_copy copier(
		.address(copy_address),
		.color_in(),
		.x(x),
		.y(y),
		.color_out(),
		.plot(writeEn),
		.done(copy_done),
		.clock(clock),
		.enable(copy_enable)
	);
		
	// everything below is game core
		
	wire [14:0] initial_address;
	wire [2:0] initial_colour;
		
	game_initial gi(
		.address(initial_address),
		.q(initial_colour),
		.clock(clock)
	);
	
	reg initial_enable;
	wire [7:0] initial_x;
	wire [6:0] initial_y;
	wire initial_wren;
	wire initial_done;
	
	state_copy initializer(
		.address(initial_address),
		.color_in(),
		.x(initial_x),
		.y(initial_y),
		.color_out(),
		.plot(initial_wren),
		.done(initial_done),
		.clock(clock),
		.enable(initial_enable)
	);
		 	
		
	localparam
	DRAW_BOARD = 5'b10000, // draws the board, based on initial.mif
	//DRAW_BOARD_1 = 5'b10001,
	INIT = 5'b00000, // initializes stuff, such as the goal's position
	START = 5'b00001, // start the game
	CHECK = 5'b00010, // check the tank's position
	DEFEAT = 5'b11111, // both tanks have lost
	
	VICTORY = 5'b00011, // tank's position is equal to the goal's position
	//DEFEAT = 5'b01111, // tank's position is equal to the mine's position
	NEW_XY_COLOUR = 5'b00100, // new colour for the tank
	NEW_XY = 5'b00101, // new position for the tank
	OLD_XY = 5'b00110, // old position of the tank
	SLEEP = 5'b00111, // used for a counter
	SHOOT = 5'b01000, // when the player presses the shoot button
	SHOOT_2 = 5'b01001, // missiles are made of 2 pixels, and SHOOT2 represents the second one
	READ_MISSILE = 5'b01010,
	READ_COLOUR = 5'b01011, // read the colour of the next pixel the missile is going towards
	NEW_MISSILE = 5'b01100, // missile's new position
	OLD_MISSILE = 5'b01101; // missile's old position
	
	// exact same thing as above, these represent player 2
	localparam
	VICTORY2 = 5'b10011, // tank's position is equal to the goal's position
	//DEFEAT2 = 5'b11111, // tank's position is equal to the mine's position
	NEW_XY_COLOUR2 = 5'b10100, // new colour for the tank
	NEW_XY2 = 5'b10101, // new position for the tank
	OLD_XY2 = 5'b10110, // old position of the tank
	SLEEP2 = 5'b10111, // used for a counter
	SHOOT2 = 5'b11000, // when the player presses the shoot button
	SHOOT_22 = 5'b11001, //missiles are made of 2 pixels, and SHOOT22 represents the second one
	READ_MISSILE2 = 5'b11010,
	READ_COLOUR2 = 5'b11011, // read the colour of the next pixel the missile is going towards
	NEW_MISSILE2 = 5'b11100, // missile's new position
	OLD_MISSILE2 = 5'b11101; // missile's old position
	
	// OLD_XY = delete tank by drawing black square
	// NEW_XY = new tank location
	
	// increase the number of states when needed
	reg [4:0] state;
	reg [4:0] next_state;
	
	wire clock;
	assign clock = CLOCK_50;
	
	// ----------STATE TABLE ----------
	reg win, lose;
	reg win2, lose2;
	
	always @ (*)
	begin
		case (state)
			DRAW_BOARD: begin
				next_state = initial_done ? INIT : DRAW_BOARD;
			end
			INIT: begin
				next_state = SLEEP;
			end
			START: begin
				next_state = CHECK;
			end
			CHECK: begin // if you win, go to VICTORY state, otherwise draw new XY location
				//next_state = win ? VICTORY : NEW_XY_COLOUR;
				if (win) begin
					next_state = VICTORY;
				end
				else if (lose & lose2) begin
					next_state = DEFEAT;
				end
				else if (win2) begin
					next_state = VICTORY2;
				end
				else begin
					next_state = NEW_XY_COLOUR;
				end
			end
			
			VICTORY: begin // if you win, games over, stay in the VICTORY state
				next_state = VICTORY;
			end
			DEFEAT: begin
				next_state = DEFEAT;
			end
			NEW_XY_COLOUR: begin
				next_state = NEW_XY;
			end
			NEW_XY: begin
				next_state = OLD_XY;
			end
			OLD_XY: begin
				next_state = SHOOT;
			end
			SHOOT: begin
				next_state = SHOOT_2;
			end
			SHOOT_2: begin
				next_state = READ_MISSILE;
			end
			READ_MISSILE: begin
				next_state = (missile_index < missile_count) ? READ_COLOUR : NEW_XY_COLOUR2;
			end
			READ_COLOUR: begin
				next_state = NEW_MISSILE;
			end
			NEW_MISSILE: begin
				next_state = OLD_MISSILE;
			end
			OLD_MISSILE: begin
				next_state = READ_MISSILE;
			end
			
			VICTORY2: begin // if you win, games over, stay in the VICTORY state
				next_state = VICTORY2;
			end
			NEW_XY_COLOUR2: begin
				next_state = NEW_XY2;
			end
			NEW_XY2: begin
				next_state = OLD_XY2;
			end
			OLD_XY2: begin
				next_state = SHOOT2;
			end
			SHOOT2: begin
				next_state = SHOOT_22;
			end
			SHOOT_22: begin
				next_state = READ_MISSILE2;
			end
			READ_MISSILE2: begin
				next_state = (missile_index2 < missile_count2) ? READ_COLOUR2 : SLEEP;
			end
			READ_COLOUR2: begin
				next_state = NEW_MISSILE2;
			end
			NEW_MISSILE2: begin
				next_state = OLD_MISSILE2;
			end
			OLD_MISSILE2: begin
				next_state = READ_MISSILE2;
			end
			
			SLEEP: begin // increase the number to slow down the speed of the tank, and vice versa
				next_state = (counter > 5_000_000) ? START : SLEEP;
			end
			default: begin
				next_state = DRAW_BOARD;
			end
		endcase
	end
	
	// ---------- STATE TRANSITIONS ----------
	
	// tank's current position
	reg [7:0] current_x;
	reg [6:0] current_y;

	// tank's new position when it moves
	reg [7:0] next_x;
	reg [6:0] next_y;
	reg [31:0] counter;
	
	// target is the goal - its own x and y values
	reg [7:0] target_x;
	reg [6:0] target_y;
	
	reg [2:0] temp_colour; // the colour the missile will end up
	reg [2:0] next_colour; // used for the tank - goes with current_x and current_y
	reg [2:0] current_colour; // used for the tank - goes with current_x and current_y
	
	reg [8:0] missile_count;
	reg [7:0] delta_x; // FF = -1 = left, 1 = right
	reg [6:0] delta_y; // FF = -1 = up, 1 = down
	reg [8:0] missile_index;
	
	reg fire_cooldown;
	reg defeat;
	
	// player 2 variables
	reg [7:0] current_x2;
	reg [6:0] current_y2;
	reg [7:0] next_x2;
	reg [6:0] next_y2;
	reg [2:0] temp_colour2;
	reg [2:0] next_colour2;
	reg [2:0] current_colour2;
	reg [8:0] missile_count2;
	reg [7:0] delta_x2;
	reg [6:0] delta_y2;
	reg [8:0] missile_index2;
	reg fire_cooldown2;
	reg defeat2;
	
	always @ (posedge clock)
	begin
		if (~resetn) begin
			//state <= INIT;
			state <= DRAW_BOARD;
			current_x <= 8'h00;
			next_x <= 8'h00;
			current_y <= 7'h00;
			next_y <= 7'h00;
			counter <= 0;
			target_x <= 8'h00;
			target_y <= 7'h00;
			delta_x <= 8'b00;
			delta_y <= 7'h00;
			temp_colour <= 3'b000;
			next_colour <= 3'b000;
			current_colour <= 3'b000;
			missile_count <= 9'h000;
			missile_index <= 9'h000;
			fire_cooldown <= 1'b0;
			defeat <= 1'b0;
			
			if (SW[16]) begin
				current_x2 <= 8'h01;
				current_y2 <= 7'h00;
				next_x2 <= 8'h01;
				next_y2 <= 7'h00;
			end
			else  begin
				current_x2 <= 8'd159;
				current_y2 <= 7'd119;
				next_x2 <= 8'd159;
				next_y2 <= 7'd119;
			end
			delta_x2 <= 8'h00;
			delta_y2 <= 7'h00;
			temp_colour2 <= 3'b000;
			next_colour2 <= 3'b000;
			current_colour2 <= 3'b000;
			missile_count2 <= 9'h000;
			missile_index2 <= 9'h000;;
			fire_cooldown2 <= 1'b0;
			defeat2 <= 1'b0;
		end
		else begin
			state <= next_state;
			if (update_target_xy) begin
				target_x <= core_x;
				target_y <= core_y;
			end
			
			if (reset_counter) begin
				counter <= 0;
			end
			else begin
				counter <= counter + 1;
			end
			
			// player 1
			if (update_current_xy) begin
				current_x <= next_x;
				current_y <= next_y;
				delta_x <= next_x - current_x;
				delta_y <= next_y - current_y;
				current_colour <= next_colour;
			end
			if (update_next_xy) begin
				next_x <= core_x;
				next_y <= core_y;
				next_colour <= core_q;
			end
			
			if (update_temp_colour) begin
				temp_colour <= core_q;
			end
			
			if (create_missile) begin
				missile_count <= missile_count + 9'h001;
			end
			if (reset_missile_index) begin
				missile_index <= 9'h000;
			end
			else if (update_missile_index) begin
				missile_index <= missile_index + 9'h001;
			end
			
			if (start_fire_cooldown) begin
				fire_cooldown <= 1'b1;
			end
			else if (end_fire_cooldown) begin
				fire_cooldown <= 1'b0;
			end
			
			if (lose) begin
				defeat <= 1'b1;
			end
			
			// player 2
			if (update_current_xy2) begin
				current_x2 <= next_x2;
				current_y2 <= next_y2;
				delta_x2 <= next_x2 - current_x2;
				delta_y2 <= next_y2 - current_y2;
				current_colour2 <= next_colour2;
			end
			if (update_next_xy2) begin
				next_x2 <= core_x;
				next_y2 <= core_y;
				next_colour2 <= core_q;
			end
			
			if (update_temp_colour2) begin
				temp_colour2 <= core_q;
			end
			
			if (create_missile2) begin
				missile_count2 <= missile_count2 + 9'h001;
			end
			if (reset_missile_index2) begin
				missile_index2 <= 9'h000;
			end
			else if (update_missile_index2) begin
				missile_index2 <= missile_index2 + 9'h001;
			end
			
			if (start_fire_cooldown2) begin
				fire_cooldown2 <= 1'b1;
			end
			else if (end_fire_cooldown2) begin
				fire_cooldown2 <= 1'b0;
			end
			
			if (lose2) begin
				defeat2 <= 1'b1;
			end
		end
	end
	
	// ---------- STATE OUTPUTS ----------
	reg update_next_xy, update_current_xy, reset_counter;
	reg update_target_xy;
	reg create_missile, update_missile, reset_missile_index, update_missile_index;
	reg start_fire_cooldown, end_fire_cooldown;
	reg [35:0] missile_data;
	reg [8:0] missile_address;
	
	reg update_temp_colour;
	
	reg update_next_xy2, update_current_xy2;
	reg create_missile2, update_missile2, reset_missile_index2, update_missile_index2;
	reg start_fire_cooldown2, end_fire_cooldown2;
	reg [35:0] missile_data2;
	reg [8:0] missile_address2;
	reg update_temp_colour2;
	
//	reg update_next_block1_xy, update_current_block1_xy;
	wire up, down, left, right;
	assign up = ~KEY[0];
	assign down = ~KEY[1];
	assign left = ~KEY[2];
	assign right = ~KEY[3];
	wire fire;
	assign fire = SW[15];
	
	reg input_reset;
	
	// datapath
	always @ (*)
	begin
		input_reset = 1'b0;
		core_wren = 1'b0;
		core_x = 8'h00;
		core_y = 7'h00;
		core_colour = 3'b000;
		update_current_xy = 1'b0;
		update_next_xy = 1'b0;
		reset_counter = 1'b0;
		update_target_xy = 1'b0;
		LEDR[7:0] = {8{1'b0}};
		LEDG[7:0] = {8{1'b0}};
		copy_enable = 1'b0;
		update_temp_colour = 1'b0;
		win = 1'b0;
		lose = 1'b0;
		create_missile = 1'b0;
		update_missile = 1'b0;
		reset_missile_index = 1'b0;
		update_missile_index = 1'b0;
		missile_address = 9'h000;
		missile_data = 36'h000000000;
		start_fire_cooldown = 1'b0;
		end_fire_cooldown = 1'b0;
		update_current_xy2 = 1'b0;
		update_next_xy2 = 1'b0;
		update_temp_colour2 = 1'b0;
		win2 = 1'b0;
		lose2 = 1'b0;
		create_missile2 = 1'b0;
		update_missile2 = 1'b0;
		reset_missile_index2 = 1'b0;
		update_missile_index2 = 1'b0;
		missile_address2 = 9'h000;
		missile_data2 = 36'h000000000;
		start_fire_cooldown2 = 1'b0;
		end_fire_cooldown2 = 1'b0;
		
		initial_enable = 1'b0;
		case (state)
			DRAW_BOARD: begin
				initial_enable = 1'b1;
				core_x = initial_x;
				core_y = initial_y;
				core_colour = initial_colour;
				core_wren = initial_wren;
			end
			INIT: begin // initialize the location of the target
				core_wren = 1'b1;
				core_x = SW[14:7];
				core_y = SW[6:0];
				core_colour = 3'b101; // pink/purple colour
				update_target_xy = 1'b1;
			end
			START: begin
				reset_counter = 1'b1;
			end
			CHECK: begin // tank is touching the target (goal)
				if (current_x == target_x && current_y == target_y) begin
					win = 1'b1;
				end
				if (current_colour == 3'b110) begin
					lose = 1'b1;
				end
				if (current_x2 == target_x && current_y2 == target_y) begin
					win2 = 1'b1;
				end
				if (current_colour2 == 3'b110) begin
					lose2 = 1'b1;
				end
			end
			DEFEAT: begin
				lose = 1'b1;
				lose2 = 1'b1;
			end
			
			VICTORY: begin
				//LEDR = {18{1'b1}};
				LEDR[7:0] = {8{1'b1}};
				win = 1'b1;
			end
			NEW_XY_COLOUR: begin
				if (left | key_left) // if the tank is able to move, check its destination's colour.
					core_x = current_x > 8'h00 ? current_x - 8'h01 : current_x;
				else if (right | key_right)
					core_x = current_x < 8'd159 ? current_x + 8'h01 : current_x;
				else
					core_x = current_x;
				if (up | key_up)
					core_y = current_y > 7'h00 ? current_y - 7'h01 : current_y;
				else if (down | key_down)
					core_y = current_y < 7'd119 ? current_y + 7'h01 : current_y;
				else
					core_y = current_y;
			end
			NEW_XY: begin
				if (left | key_left) // keep moving until you have hit the edge of the screen. Applies to all other directions
					core_x = current_x > 8'h00 ? current_x - 8'h01 : current_x;
				else if (right | key_right)
					core_x = current_x < 8'd159 ? current_x + 8'h01 : current_x;
				else
					core_x = current_x;
				if (up | key_up)
					core_y = current_y > 7'h00 ? current_y - 7'h01 : current_y;
				else if (down | key_down)
					core_y = current_y < 7'd119 ? current_y + 7'h01 : current_y;
				else
					core_y = current_y;
				// if the colour received from core is not green or turquoise
				if (core_q != 3'b010 && core_q != 3'b011 && core_q != 3'b100 && (!defeat)) begin
					core_wren = 1'b1;
					core_colour = 3'b111;
					update_next_xy = 1'b1;
				end
			end
			OLD_XY: begin
			   if ((next_x != current_x || next_y != current_y) && (~defeat)) begin
					core_wren = 1'b1;
					core_x = current_x;
					core_y = current_y;
					core_colour = current_colour;
					update_current_xy = 1'b1;
				end
			end
			SHOOT: begin
				if ((key_fire || fire) && missile_count != 9'h1ff && !fire_cooldown && (~defeat)) begin
					create_missile = 1'b1;
					missile_data = {3'b111, current_x, current_y, delta_x, delta_y};
					missile_address = missile_count;
					
					core_x = current_x + delta_x;
					core_y = current_y + delta_y;
				end
			end
			SHOOT_2: begin
				if ((key_fire || fire) && missile_count != 9'h1ff && !fire_cooldown && (~defeat)) begin
					create_missile = 1'b1;
					missile_data = {core_q, current_x + delta_x, current_y + delta_y, delta_x, delta_y};
					missile_address = missile_count;
					start_fire_cooldown = 1'b1;
				end
				else begin
					end_fire_cooldown = 1'b1;
				end
				reset_missile_index = 1'b1;
				//input_reset = 1'b1;
			end
			READ_MISSILE: begin
				missile_address = missile_index;
			end
			READ_COLOUR: begin
				missile_address = missile_index;
				// adding delta_x or delta_y twice to move faster than the tank
				core_x = missile_q[29:22] + missile_q[14:7] + missile_q[14:7];
				core_y = missile_q[21:15] + missile_q[6:0] + missile_q[6:0];
			end
			NEW_MISSILE: begin
				missile_address = missile_index;
				// x = [29:22], delta_x = [14:7]
				// y = [21:15], delta_y = [6:0]
				
				// checking the bound of the missile
				// (ie. if delta_x is positive (right) and less than 158 (right boundary of screen), or ...
				// same expression for other directions)
				if ((((missile_q[14] == 1'b0) && (missile_q[29:22] < 158))
						|| ((missile_q[14] == 1'b1) && (missile_q[29:22] > 1)) || (missile_q[14:7] == 0))
						&& (((missile_q[6] == 1'b0) && (missile_q[21:15] < 118))
						|| ((missile_q[6] == 1'b1) && (missile_q[21:15] > 1)) || (missile_q[6:0] == 0))) begin
					core_wren = 1'b1;
					core_x = missile_q[29:22] + missile_q[14:7] + missile_q[14:7];
					core_y = missile_q[21:15] + missile_q[6:0] + missile_q[6:0];
					if (missile_q[32:30] == 3'b010 || missile_q[32:30] == 3'b011) begin
						core_colour = core_q;
					end
					else begin
						core_colour = 3'b001;
					end
					update_temp_colour = 1'b1;
				end
			end
			OLD_MISSILE: begin
				missile_address = missile_index;
				update_missile = 1'b1;
				update_missile_index = 1'b1;
				core_wren = 1'b1;
				core_x = missile_q[29:22];
				core_y = missile_q[21:15];
				if (missile_q[32:30] == 3'b010) begin
					core_colour = 3'b000;
					missile_data = 36'h000000000;
				end
				else if (missile_q[32:30] == 3'b011) begin
					core_colour = 3'b011;
					missile_data = 36'h000000000;
				end
				else begin
					core_colour = missile_q[32:30];
					if ((((missile_q[14] == 1'b0) && (missile_q[29:22] < 158))
							|| ((missile_q[14] == 1'b1) && (missile_q[29:22] > 1)) || (missile_q[14:7] == 0))
							&& (((missile_q[6] == 1'b0) && (missile_q[21:15] < 118))
							|| ((missile_q[6] == 1'b1) && (missile_q[21:15] > 1)) || (missile_q[6:0] == 0))) begin
						missile_data = {temp_colour, missile_q[29:22] + missile_q[14:7] + missile_q[14:7], 
								missile_q[21:15] + missile_q[6:0] + missile_q[6:0], missile_q[14:0]};
					end
					else begin
						missile_data = 36'h000000000;
					end
				end
			end
			
			// PLAYER 2 - exact same logic as player 1, except it has "player 2 variables"
			VICTORY2: begin
				//LEDR = {18{1'b1}};
				LEDG = {8{1'b1}};
				win2 = 1'b1;
			end
			NEW_XY_COLOUR2: begin
				if (key_left2) // if the tank is able to move, check its destination's colour.
					core_x = current_x2 > 8'h00 ? current_x2 - 8'h01 : current_x2;
				else if (key_right2)
					core_x = current_x2 < 8'd159 ? current_x2 + 8'h01 : current_x2;
				else
					core_x = current_x2;
				if (key_up2)
					core_y = current_y2 > 7'h00 ? current_y2 - 7'h01 : current_y2;
				else if (key_down2)
					core_y = current_y2 < 7'd119 ? current_y2 + 7'h01 : current_y2;
				else
					core_y = current_y2;
			end
			NEW_XY2: begin
				if (key_left2) // keep moving until you have hit the edge of the screen. Applies to all other directions
					core_x = current_x2 > 8'h00 ? current_x2 - 8'h01 : current_x2;
				else if (key_right2)
					core_x = current_x2 < 8'd159 ? current_x2 + 8'h01 : current_x2;
				else
					core_x = current_x2;
				if (key_up2)
					core_y = current_y2 > 7'h00 ? current_y2 - 7'h01 : current_y2;
				else if (key_down2)
					core_y = current_y2 < 7'd119 ? current_y2 + 7'h01 : current_y2;
				else
					core_y = current_y2;
				// if the colour received from core is not green or turquoise
				if (core_q != 3'b010 && core_q != 3'b011 && core_q != 3'b111 && (~defeat2)) begin
					core_wren = 1'b1;
					core_colour = 3'b100;
					update_next_xy2 = 1'b1;
				end
			end
			OLD_XY2: begin
			   if ((next_x2 != current_x2 || next_y2 != current_y2) && (~defeat2)) begin
					core_wren = 1'b1;
					core_x = current_x2;
					core_y = current_y2;
					core_colour = current_colour2;
					update_current_xy2 = 1'b1;
				end
			end
			SHOOT2: begin
				if ((key_fire2) && missile_count2 != 9'h1ff && !fire_cooldown2 && (~defeat2)) begin
					create_missile2 = 1'b1;
					missile_data2 = {3'b100, current_x2, current_y2, delta_x2, delta_y2};
					missile_address2 = missile_count2;
					
					core_x = current_x2 + delta_x2;
					core_y = current_y2 + delta_y2;
				end
			end
			SHOOT_22: begin
				if ((key_fire2) && missile_count2 != 9'h1ff && !fire_cooldown2 && (~defeat2)) begin
					create_missile2 = 1'b1;
					missile_data2 = {core_q, current_x2 + delta_x2, current_y2 + delta_y2, delta_x2, delta_y2};
					missile_address2 = missile_count2;
					start_fire_cooldown2 = 1'b1;
				end
				else begin
					end_fire_cooldown2 = 1'b1;
				end
				reset_missile_index2 = 1'b1;
				input_reset = 1'b1;
			end
			READ_MISSILE2: begin
				missile_address2 = missile_index2;
			end
			READ_COLOUR2: begin
				missile_address2 = missile_index2;
				core_x = missile_q2[29:22] + missile_q2[14:7] + missile_q2[14:7];
				core_y = missile_q2[21:15] + missile_q2[6:0] + missile_q2[6:0];
			end
			NEW_MISSILE2: begin
				missile_address2 = missile_index2;
				// x = [29:22], delta_x = [14:7]
				// y = [21:15], delta_y = [6:0]
				if ((((missile_q2[14] == 1'b0) && (missile_q2[29:22] < 158))
						|| ((missile_q2[14] == 1'b1) && (missile_q2[29:22] > 1)) || (missile_q2[14:7] == 0))
						&& (((missile_q2[6] == 1'b0) && (missile_q2[21:15] < 118))
						|| ((missile_q2[6] == 1'b1) && (missile_q2[21:15] > 1)) || (missile_q2[6:0] == 0))) begin
					core_wren = 1'b1;
					core_x = missile_q2[29:22] + missile_q2[14:7] + missile_q2[14:7];
					core_y = missile_q2[21:15] + missile_q2[6:0] + missile_q2[6:0];
					if (missile_q2[32:30] == 3'b010 || missile_q2[32:30] == 3'b011) begin
						core_colour = core_q;
					end
					else begin
						core_colour = 3'b001;
					end
					update_temp_colour2 = 1'b1;
				end
			end
			OLD_MISSILE2: begin
				missile_address2 = missile_index2;
				update_missile2 = 1'b1;
				update_missile_index2 = 1'b1;
				core_wren = 1'b1;
				core_x = missile_q2[29:22];
				core_y = missile_q2[21:15];
				if (missile_q2[32:30] == 3'b010) begin
					core_colour = 3'b000;
					missile_data2 = 36'h000000000;
				end
				else if (missile_q2[32:30] == 3'b011) begin
					core_colour = 3'b011;
					missile_data2 = 36'h000000000;
				end
				else begin
					core_colour = missile_q2[32:30];
					if ((((missile_q2[14] == 1'b0) && (missile_q2[29:22] < 158))
							|| ((missile_q2[14] == 1'b1) && (missile_q2[29:22] > 1)) || (missile_q2[14:7] == 0))
							&& (((missile_q2[6] == 1'b0) && (missile_q2[21:15] < 118))
							|| ((missile_q2[6] == 1'b1) && (missile_q2[21:15] > 1)) || (missile_q2[6:0] == 0))) begin
						missile_data2 = {temp_colour2, missile_q2[29:22] + missile_q2[14:7] + missile_q2[14:7], 
								missile_q2[21:15] + missile_q2[6:0] + missile_q2[6:0], missile_q2[14:0]};
					end
					else begin
						missile_data2 = 36'h000000000;
					end
				end
			end
			
			SLEEP: begin
				copy_enable = 1'b1;
			end
		endcase
	end
	
	// game time counter
	wire [3:0] V0;
	wire [3:0] V1;
	wire [3:0] V2;
	wire [3:0] V3;
	
	decimal_counter dc(
		.V3(V3),
		.V2(V2),
		.V1(V1),
		.V0(V0),
		.reset(~resetn),
		.clock(clock_1000ms),
		.enable((~win) & (~win2) & (~(defeat & defeat2)))
	);
	
	// displaying the timer
	hex_display h0(V0, HEX0);
	hex_display h1(V1, HEX1);
	hex_display h2(V2, HEX2);
	hex_display h3(V3, HEX3);
	
	// displaying the amount of missiles used for player 2
	hex_display h4(missile_count2[4:1], HEX4);
	hex_display h5(missile_count2[8:5], HEX5);
	
	// displaying the amount of missiles used for player 1
	hex_display h6(missile_count[4:1], HEX6);
	hex_display h7(missile_count[8:5], HEX7);
	
	always @ (*)
	begin
		LEDR[17:13] = {key_up, key_down, key_left, key_right, key_fire};
		LEDR[12:8] = {key_up2, key_down2, key_left2, key_right2, key_fire2};
	end
	
	// slow clock generates
	wire clock_1000ms;
	
	slow_clocks sc(
		.clock_1000ms(clock_1000ms),
		.reset(1'b0),
		.CLOCK_50(CLOCK_50),
		.enable(1'b1)
	);
		
	// input decoder
	
	wire key_up, key_down, key_left, key_right, key_fire;
	wire key_up2, key_down2, key_left2, key_right2, key_fire2;
	
	input_decoder decode(
		.up(key_up),
		.down(key_down),
		.left(key_left),
		.right(key_right),
		.fire(key_fire),
		.up2(key_up2),
		.down2(key_down2),
		.left2(key_left2),
		.right2(key_right2),
		.fire2(key_fire2),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.reset(input_reset),
		.CLOCK_50(CLOCK_50)
	);
		
	// missile memory
		
	wire [35:0] missile_q;
		
	missiles ms(
		.address(missile_address),
		.data(missile_data),
		.clock(clock),
		.wren(create_missile | update_missile),
		.q(missile_q)
	);
	
	wire [35:0] missile_q2;
		
	missiles ms2(
		.address(missile_address2),
		.data(missile_data2),
		.clock(clock),
		.wren(create_missile2 | update_missile2),
		.q(missile_q2)
	);
		
endmodule
