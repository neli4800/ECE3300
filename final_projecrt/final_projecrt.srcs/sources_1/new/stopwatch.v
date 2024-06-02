`timescale 1ns / 1ps


module stopwatch(input wire clk,
	             input wire go, stop, clr, 
	             output wire [3:0] d3, d2, d1, d0
            	);
	
	
	// declarations for FSM circuit
	reg state_reg, state_next;           // register for current state and next state     
	
	localparam off = 1'b0,               // states 
	           on = 1'b1;
	// state register
   always @(posedge clk, posedge clr)
       if(clr)
	 state_reg <= 0;
       else 
         state_reg <= state_next;

   // FSM next state logic
   always @*
       case(state_reg)
         off:begin
	     if(go)
                state_next = on;
	     else 
		state_next = off;
	     end
			
         on: begin
	     if(stop)
               state_next = off;
	     else 
	       state_next = on;
             end
        endcase	
  // declarations for counter circuit
	localparam divisor = 50000000;                  // number of clock cycles in 1 s, for mod-50M counter
	reg [26:0] sec_reg;                             // register for second counter
	wire [26:0] sec_next;                           // next state connection for second counter
	reg [3:0] d3_reg, d2_reg, d1_reg, d0_reg;       // registers for decimal values displayed on 4 digit displays
	wire [3:0] d3_next, d2_next, d1_next, d0_next;  // next state wiring for 4 digit displays
	wire d3_en, d2_en, d1_en, d0_en;                // enable signals for display multiplexing 
	wire sec_tick, d0_tick, d1_tick, d2_tick;       // signals to enable next stage of counting

        // counter register 
	always @(posedge clk)
	    begin
	       sec_reg <= sec_next;
	       d0_reg  <= d0_next;
	       d1_reg  <= d1_next;
	       d2_reg  <= d2_next; 
	       d3_reg  <= d3_next;
            end
	
	// next state logic 
	// 1 second tick generator : mod-50M
	assign sec_next = (clr || sec_reg == divisor && (state_reg == on)) ? 4'b0 : 
	                  (state_reg == on) ? sec_reg + 1 : sec_reg;
	
	assign sec_tick = (sec_reg == divisor) ? 1'b1 : 1'b0;
	
	// second ones counter 
	assign d0_en   = sec_tick; 
	
	assign d0_next = (clr || (d0_en && d0_reg == 9)) ? 4'b0 : 
	                  d0_en ? d0_reg + 1 : d0_reg; 
	
	assign d0_tick = (d0_reg == 9) ? 1'b1 : 1'b0;
							
	// second tenths counter 
	assign d1_en = sec_tick & d0_tick; 
	
	assign d1_next = (clr || (d1_en && d1_reg == 5)) ? 4'b0 : 
	                  d1_en ? d1_reg + 1 : d1_reg; 	
							
	assign d1_tick = (d1_reg == 5) ? 1'b1 : 1'b0;
	
	// minute ones counter 
	assign d2_en = sec_tick & d0_tick & d1_tick; 
	
	assign d2_next = (clr || (d2_en && d2_reg == 9)) ? 4'b0 : 
	                  d2_en ? d2_reg + 1 : d2_reg;
	
        assign d2_tick = (d2_reg == 9) ? 1'b1 : 1'b0;	
	
	// minute tenths counter 
	assign d3_en = sec_tick & d0_tick & d1_tick & d2_tick; 
	
	assign d3_next = (clr || (d3_en && d3_reg == 9)) ? 4'b0 : 
	                  d3_en ? d3_reg + 1 : d3_reg;
       
       // route digit registers to output 
       assign d0 = d0_reg; 
       assign d1 = d1_reg; 
       assign d2 = d2_reg;
       assign d3 = d3_reg;             
	           
	
endmodule






module DigitalClock(input system_clk, output  [7:0]sevenseg, output [7:0] AN );
wire o,f;
wire [1:0] a; 
wire [5:0] s, m;
wire [3:0] sec, min; 
wire [3:0] s1, s2, m1, m2, Q;



slowerClkGen b(.system_clk(system_clk), .outsignal_1s(o), .outsignal_400(f));
twobit_counter z(.clk(f), .s(a));
decoder w(.data(a),.AN(AN));
clock d(.Clk_1sec(o), .reset(0), .seconds(s), .minutes(m));
binary q(.binary(s), .tens(s1), .ones(s2));
binary h(.binary(m), .tens(m1), .ones(m2));
mux4to1 r(.select(a), .D1(s2), .D2(s1), .D3(m2), .D4(m1), .Q(Q));
segdisp( .in(Q), .seven_seg(sevenseg));
endmodule


    
module slowerClkGen(system_clk, outsignal_1s, outsignal_400);
input system_clk;
output reg outsignal_1s;
output reg outsignal_400;
reg [26:0] counter1; 
reg [26:0] counter2; 
reg outsignal;
    always @ (posedge system_clk)

begin
    counter1 = counter1 +1;
    counter2 = counter2 +1;
 if (counter1 == 50_000_000) //
begin
    outsignal_1s=~outsignal_1s;
    counter1 =0;
end
if (counter2 == 125_000) //
begin
    outsignal_400=~outsignal_400;
    counter2 =0;
end
 end
   
endmodule   
    

module clock(
    Clk_1sec,  //Clock with 1 Hz frequency
    reset,     //active high reset
    seconds,
    minutes);

//What are the Inputs?
    input Clk_1sec;  
    input reset;
//What are the Outputs? 
    output [5:0] seconds;
    output [5:0] minutes;
    
//Internal variables.
    reg [5:0] seconds;
    reg [5:0] minutes;
     

   //Execute the always blocks when the Clock or reset inputs are 
    //changing from 0 to 1(positive edge of the signal)
    always @(posedge(Clk_1sec))
    begin
        if(reset == 1'b1) begin  //check for active high reset.
            //reset the time.
            seconds = 0;
            minutes = 0;           
     end
                if(seconds < 59) begin  //at the beginning of each second
            seconds <= seconds + 1; //increment sec
            end
        else if(seconds == 6'd59) begin //check for max value of sec
                seconds <= 0;  //reset seconds
            minutes <= minutes + 1; //increment sec
                end 
        else if(minutes == 6'd59) begin //check for max value of sec
                minutes <= 0;  //reset seconds
                
                end 
    end       
          
endmodule


module binary (
input [5:0] binary,
output reg [3:0] tens,
output reg [3:0] ones);

reg [5:0] bcd_d = 0;
always @ (binary)
begin bcd_d = binary;
tens = bcd_d/10;
ones= bcd_d%10;

end
endmodule






module twobit_counter(clk, s);
input clk;
output reg [1:0]s;
always @ (posedge clk)
    s <= s+1;
endmodule

module segdisp(input [3:0] in, output reg[7:0] seven_seg);

always @(in)
begin 
 

case (in)
4'b0000 : begin seven_seg = 8'b11000000; end
4'b0001 : begin seven_seg = 8'b11111001; end
4'b0010 : begin seven_seg = 8'b10100100; end
4'b0011 : begin seven_seg = 8'b10110000; end
4'b0100 : begin seven_seg = 8'b10011001; end
4'b0101 : begin seven_seg = 8'b10010010; end
4'b0110 : begin seven_seg = 8'b10000010; end
4'b0111 : begin seven_seg = 8'b11111000; end
4'b1000 : begin seven_seg = 8'b10000000; end
4'b1001 : begin seven_seg = 8'b10010000; end
endcase
end
endmodule

module mux4to1(input [1:0] select, input [3:0] D1, D2, D3, D4, output reg [3:0] Q);
    always @ (select,D1, D2, D3, D4)
    begin
    case(select)
        2'b01 : Q = D2;
        2'b10 : Q = D3;
        2'b11 : Q = D4;
      default : Q = D1;
      endcase
    end
 endmodule
 
 
    
    
//declare the Verilog module - The inputs and output port names.
module decoder  //beginning of the module description
(input [1:0] data,  output reg [7:0] AN ); //define input and output
always @(data) //the always block
begin //the beginning of the always block 
       AN=8'b11111111; //reset output y; all 8 bits are set to 0
       case(data)
            2'b00 : AN = 8'b11111110; 
            2'b01 : AN = 8'b11111101;
            2'b10 : AN = 8'b11111011;
            2'b11 : AN = 8'b11110111;
            default : AN =8'b11111111;
            endcase
end
endmodule
            

