`timescale 1ns / 1ps

module decoder  //beginning of the module description
(input [5:0] data,  output reg [63:0] y ); //define input and output
always @(data) //the always block
 begin //the beginning of the always block 
       y=0; //reset output y; all 8 bits are set to 0
       y[data]=1; //output y is set according to data; only the corresponding (data) bit is set to 1
end //the end of the always block
endmodule