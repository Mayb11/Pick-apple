module Apple_pick (
    // Global Clock/Reset
    // - Clock
    input              clock,
    // - Global Reset
    input              globalReset,
	 // people movement
	 input right,
	 input left,
	 input switch,
    // - Application Reset - for debug
    output             resetApp,
	 // state of success or not
	 output 			reg	 SUCCESS,
	 output			reg		  FAIL,
    
    // LT24 Interface
    output             LT24Wr_n,
    output             LT24Rd_n,
    output             LT24CS_n,
    output             LT24RS,
    output             LT24Reset_n,
    output [     15:0] LT24Data,
    output             LT24LCDOn
);

//
// Local Variables
//
reg  [ 7:0] xAddr;
reg  [ 8:0] yAddr;
reg  [15:0] pixelData;
wire        pixelReady;
reg         pixelWrite;

reg [3:0] state;

localparam SHOWING=4'b0001;
localparam RIGHT=4'b0010;
localparam LEFT=4'b0100;
localparam FALLING=4'b1000;
//localparam s5=5'b10000;

//
// LCD Display
//
localparam LCD_WIDTH  = 240;
localparam LCD_HEIGHT = 320;

LT24Display #(
    .WIDTH       (LCD_WIDTH  ),
    .HEIGHT      (LCD_HEIGHT ),
    .CLOCK_FREQ  (50000000   )
) Display (
    //Clock and Reset In
    .clock       (clock      ),
    .globalReset (globalReset),
    //Reset for User Logic
    .resetApp    (resetApp   ),
    //Pixel Interface
    .xAddr       (xAddr      ),
    .yAddr       (yAddr      ),
    .pixelData   (pixelData  ),
    .pixelWrite  (pixelWrite ),
    .pixelReady  (pixelReady ),
    //Use pixel addressing mode
    .pixelRawMode(1'b0       ),
    //Unused Command Interface
    .cmdData     (8'b0       ),
    .cmdWrite    (1'b0       ),
    .cmdDone     (1'b0       ),
    .cmdReady    (           ),
    //Display Connections
    .LT24Wr_n    (LT24Wr_n   ),
    .LT24Rd_n    (LT24Rd_n   ),
    .LT24CS_n    (LT24CS_n   ),
    .LT24RS      (LT24RS     ),
    .LT24Reset_n (LT24Reset_n),
    .LT24Data    (LT24Data   ),
    .LT24LCDOn   (LT24LCDOn  )
);

// X Counter of whole screen

wire [7:0] screen_xCount;
UpCounterNbit #(
    .WIDTH    (          8),
    .MAX_VALUE(239)
) screen_xCounter (
    .clock     (clock     ),
    .reset     (resetApp  ),
    .enable    (pixelReady),
    .countValue(screen_xCount    )
);

// Y Counter of whole screen

wire [8:0] screen_yCount;
wire screen_yCntEnable = pixelReady && (screen_xCount == (239));
UpCounterNbit #(
    .WIDTH    (           9),
    .MAX_VALUE(319)
) screen_yCounter (
    .clock     (clock     ),
    .reset     (resetApp  ),
    .enable    (screen_yCntEnable),
    .countValue(screen_yCount    )
);

// parameters in this project
reg [7:0] apple_xlocation=8'd119; //apple's origin x location
reg [8:0] apple_ylocation=9'd9;//apple's origin y location
reg [7:0]people_xlocation=8'd119;//people's origin x location
reg [8:0]people_ylocation=9'd309;//people's origin y location
reg [7:0]last_people_xlocation=8'd0;//last x location of people 
reg [8:0]last_people_ylocation=9'd0;//last y location of people
reg [7:0]last_apple_xlocation=8'd0;// last x location of apple
reg [8:0]last_apple_ylocation=9'd0;// last y location of apple
reg right_last;// last state of input right, which is key2	
reg left_last;// last state of input left, which is key3
reg [7:0]T=8'd0;//use to store a random number to give a new x location of apple
reg [27:0] F=28'b0;// time counter

// state-machine. 4 states-SHOWING,to write current address and pixeldata into choosen x-y address
// RIGHT, make the people right move for 10 pixels
// LEFT, make the people left move for 10 pixels
// FALLING, make apple falling from the top at fixed speed,and check if people pick the apple or not

always @ (posedge clock or posedge resetApp) begin
	// reset all parameters
    if (resetApp) begin
		pixelWrite			  	<=1'b1;
		xAddr               	<= screen_xCount;
		yAddr               	<= screen_yCount;
		pixelData[15:11]    	<= 5'b00000;
		pixelData[10: 5]   	<= 6'b000000;
		pixelData[4:0]		  	<= 5'b11111;
		apple_xlocation	 	<=8'd119;//0~229
		apple_ylocation    	<=9'd9;//9~309
		people_xlocation	   <=8'd119;// 0~229
		people_ylocation	  	<=9'd309;
		last_people_xlocation<=8'd119;
		last_people_ylocation<=9'd309;
		last_apple_xlocation	<=8'd119;
		last_apple_ylocation	<=9'd9;
		//F<=28'd0;
		//T<=8'd0;
    end 
	 else begin
		right_last<=right;//store the value of current key2 input
		left_last<=left;//store the value of current key3 input
		
		if (F < 28'd249_999)	begin// select a number, Being too small can cause the screen to refresh too quickly to see the color block clearly. 
		//Being too large causes the screen to refresh too slowly and affects the feel of the keystrokes.
				F			<= F + 1'b1;
		end	
		else begin 
				F 			<= 28'd0; // when counter reach the peak, set counter to 0, and repeat the whole steps again
				if (T < 8'd230) begin 
					T <= T+8'd10;// add 10 each time, because block move 10 pixels one time, so this random number must be a multiple of 10.
				end
				else begin 
					T <= 8'd0;// LCD x limit is 239, so when T reach the peak, set T to 0 and repeat the whole steps again
				end
		end 
		case (state)// state machine
		
			SHOWING: begin 
				pixelWrite<=1'b1;// put this signal high to trigger a write to the addressed pixel
				SUCCESS<=1'b0;// LEDRs didn't blink
				FAIL<=1'b0;
				//When the coordinates are scanned to the selected people position, 
				//start following the determined long and high output RGB565 colors to the specified coordinates.
				if (screen_xCount >= people_xlocation && screen_xCount <= people_xlocation+8'd10 
					&& screen_yCount >= people_ylocation && screen_yCount <= people_ylocation+8'd10) begin
					xAddr               <= screen_xCount;
					yAddr               <= screen_yCount;
					pixelData[15:11]    <= 5'b00000;
					pixelData[10: 5]    <= 6'b111111;// colour is green, means "people"
					pixelData[4:0]		  <= 5'b00000;
					last_people_xlocation<=people_xlocation;// store the current value of x location of people
					last_people_ylocation<=people_ylocation;	// store the current value of y location of people
				end
				//When the coordinates are scanned to the selected apple position, 
				//start following the determined long and high output RGB565 colors to the specified coordinates.
				else if (screen_xCount >= apple_xlocation && screen_xCount <= apple_xlocation+9'd10 
						  && screen_yCount >= apple_ylocation && screen_yCount <= apple_ylocation+9'd10) begin
					xAddr               <= screen_xCount;
					yAddr               <= screen_yCount;
					pixelData[15:11]    <= 5'b11111;// colour is red, means "apple"
					pixelData[10: 5]    <= 6'b000000;
					pixelData[4:0]		  <= 5'b00000;
					last_apple_xlocation<=apple_xlocation;// store the current value of x location of apple
					last_apple_ylocation<=apple_ylocation;// store the current value of y location of apple
					
				end
				else if (!right) begin // if key2 was pressed, jump to the RIGHT state
					state <= RIGHT;
				end
				else if (!left) begin // if key3 was pressed ,jump to the LEFT state
					state <= LEFT;
				end
				else if (F == 28'd19_999) begin // give some time to clean the screen, number was filexable, just not greater than 239_999,
					state	<=	FALLING;					// then jump to the FALLING state
				end
			end
			
			RIGHT: begin 
				pixelWrite<=1'b1;
				people_xlocation<=last_people_xlocation+8'd10;// add 10 pixel to people last address, then next scan will use the new range of 
																			// people, other way, the people moved 10 pixels right
				xAddr               <= screen_xCount;// clean the whole screen, otherwise LCD will show all the appeared pixels
				yAddr               <= screen_yCount;
				pixelData[15:11]    <= 5'b00000;
				pixelData[10: 5]    <= 6'b000000;
				pixelData[4:0]		  <= 5'b00000;
				if (F == 28'd19_999) begin // give some time toe clean the screen, then jump back to the SHOWING state
					state	<=	SHOWING;
				end
			end
			
			LEFT: begin 
				pixelWrite<=1'b1;
				people_xlocation<=last_people_xlocation-8'd10;// decrease 10 pixel to people last address, then next scan will use the new 
																			// range of people, other way ,the people moved 10 pixels left
				xAddr               <= screen_xCount;// clean the whole screen, otherwise LCD will show all the appeared pixels
				yAddr               <= screen_yCount;
				pixelData[15:11]    <= 5'b00000;
				pixelData[10: 5]    <= 6'b000000;
				pixelData[4:0]		  <= 5'b00000;
				if (F == 28'd19_999) begin // give some time toe clean the screen, then jump back to the SHOWING state
					state	<=	SHOWING;
				end
			end 
			
			FALLING: begin 
				pixelWrite<=1'b1;
				if (apple_ylocation<309) begin // check if apple fallen to the people.
					apple_ylocation<=last_apple_ylocation+9'd5; // if not,falling speed is 5 pixels one time
					apple_xlocation<=last_apple_xlocation;// x location of apple didn't change
				end 
				else if (last_apple_ylocation == 9'd304) begin// When an apple falls to the same height as people
					if (apple_xlocation == people_xlocation) begin // check if the x location of apple equals to people's x location
						SUCCESS			<=1'b1; // if equal, LEDR9 light
						apple_xlocation<=T-8'd1;// use the random number as next apple's x location
						apple_ylocation<=9'd9;// y location of apple is back to the top
					end
					else begin 
						FAIL<=1'b1;// if not equal, LEDR7 light
						apple_xlocation<=T-8'd1;// use the random number as next apple 's x location
						apple_ylocation<=9'd9;// y location of apple is back to the top
					end
				end
				xAddr               <= screen_xCount;// clean the whole screen
				yAddr               <= screen_yCount;
				pixelData[15:11]    <= 5'b00000;
				pixelData[10: 5]    <= 6'b000000;
				pixelData[4:0]		  <= 5'b00000;
				if (F == 28'd19_999) begin // give some time to clean the screen,then jump back to SHOWING state
					state	<= SHOWING;
				end
			end
			default state<=SHOWING;// default state is SHOWING state
		endcase
	end
   
end
// people movement


endmodule

/*
 * N-Bit Up Counter
 * ----------------
 * By: Thomas Carpenter
 * Date: 13/03/2017 
 *
 * Short Description
 * -----------------
 * This module is a simple up-counter with a count enable.
 * The counter has parameter controlled width, increment,
 * and maximum value.
 *
 */

module UpCounterNbit #(
    parameter WIDTH = 10,               //10bit wide
    parameter INCREMENT = 1,            //Value to increment counter by each cycle
    parameter MAX_VALUE = (2**WIDTH)-1  //Maximum value default is 2^WIDTH - 1
)(   
    input                    clock,
    input                    reset,
    input                    enable,    //Increments when enable is high
    output reg [(WIDTH-1):0] countValue //Output is declared as "WIDTH" bits wide
);

always @ (posedge clock) begin
    if (reset) begin
        //When reset is high, set back to 0
        countValue <= {(WIDTH){1'b0}};
    end else if (enable) begin
        //Otherwise counter is not in reset
        if (countValue >= MAX_VALUE[WIDTH-1:0]) begin
            //If the counter value is equal or exceeds the maximum value
            countValue <= {(WIDTH){1'b0}};   //Reset back to 0
        end else begin
            //Otherwise increment
            countValue <= countValue + INCREMENT[WIDTH-1:0];
        end
    end
end

endmodule
