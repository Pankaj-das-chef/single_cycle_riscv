`timescale 1ns / 1ps


module PC_Adder (a,b,c);

    input [31:0]a,b;
    output [31:0]c;

    assign c = a + b;
    
endmodule