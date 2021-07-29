`timescale 1 ns/ 1 ns
module Apple_pick_tb();
// constants         
localparam NUM_CYCLES = 1000000;
localparam CLOCK_FREQ = 50000000;
// general purpose registers
reg eachvec;
// test vector input registers
reg clock;
reg globalReset;
reg left;
reg right;
reg switch;
// wires                                               
wire FAIL;
wire LT24CS_n;
wire [15:0]  LT24Data;
wire LT24LCDOn;
wire LT24RS;
wire LT24Rd_n;
wire LT24Reset_n;
wire LT24Wr_n;
wire SUCCESS;
wire resetApp;

// assign statements (if any)                          
Apple_pick Apple_pick_inst (
// port map - connection between master ports and signals/registers   
	.FAIL(FAIL),
	.LT24CS_n(LT24CS_n),
	.LT24Data(LT24Data),
	.LT24LCDOn(LT24LCDOn),
	.LT24RS(LT24RS),
	.LT24Rd_n(LT24Rd_n),
	.LT24Reset_n(LT24Reset_n),
	.LT24Wr_n(LT24Wr_n),
	.SUCCESS(SUCCESS),
	.clock(clock),
	.globalReset(globalReset),
	.left(left),
	.resetApp(resetApp),
	.right(right),
	.switch(switch)
);

wire [3:0] state = Apple_pick_inst.state;
wire [7:0] people_x = Apple_pick_inst.people_xlocation;
wire [8:0] people_y = Apple_pick_inst.people_ylocation;
wire [7:0] apple_x = Apple_pick_inst.apple_xlocation;
wire [8:0] apple_y = Apple_pick_inst.apple_ylocation;

initial                                                
begin                                                  
// code that executes only once                        
// insert code here --> begin  
// initialise
	globalReset <= 1'b1;
	repeat(2) @ (posedge clock);
	globalReset <= 1'b0;
	wait (resetApp === 1'b0);
	right <= 1'b1;
	left <= 1'b1;
	#200000
	// initialise completed
	// press key2, state jump into the RIGHT state(origin is in SHOWING state)
	right <= 1'b0;
	#200000
	right <= 1'b1;// release the key,wait state jump back to state SHOWING
	#200000
	left <= 1'b0;// press key3, state jump into the LEFT state
	#200000
	left <= 1'b1;// release the key, wait state jump back to state SHOWING
// --> end                                             
$display("Running testbench");                       
end    

initial 
begin
	clock = 1'b0;
end 


real HALF_CLOCK_PERIOD = (1000000000.0 / $itor(CLOCK_FREQ)) / 2.0;

integer half_cycles = 0;
                                                
always                                                 
// optional sensitivity list                           
// @(event1 or event2 or .... eventn)                  
begin                                                  
           
//Generate the next half cycle of clock
    #(HALF_CLOCK_PERIOD);          //Delay for half a clock period.
    clock = ~clock;                //Toggle the clock
    half_cycles = half_cycles + 1; //Increment the counter
    
    //Check if enough half clock cycle
    if (half_cycles == (2*NUM_CYCLES)) begin 
        //Once the number of cycles has been reached
		half_cycles = 0; 		   //Reset half cycles, so if we resume running with "run -all", we perform another chunk.
        $stop;                     //Break the simulation
        //Note: We can continue the simulation after this breakpoint using "run -continue" or "run x ns" or "run -all" in modelsim.
    end                                      
// --> end                                             
end                                                    
endmodule

