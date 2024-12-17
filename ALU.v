`timescale 1ns / 1ps

module ALU(A,B,Result,ALUControl,OverFlow,Carry,Zero,Negative);

    input [31:0]A,B;
    input [2:0]ALUControl;
    output Carry,OverFlow,Zero,Negative;
    output [31:0]Result;

    // declaring interim wires
    wire Cout;
    wire [31:0] a_and_b;
    wire [31:0] a_or_b;
    wire [31:0] not_b;
    
    wire [31:0] mux_1;
    
    wire [31:0] Sum;
    
    wire [31:0] mux_2;
    
    wire [31:0] slt;
    
    //Logic design
    assign a_and_b = A&B;
    assign a_or_b = A|B;
    assign not_b = ~B;
    
    assign mux_1 = (ALUControl[0] == 1'b0) ? B : not_b;

    assign {Cout,Sum} =A + mux_1 + ALUControl[0];
    
    //zero extension
    assign slt = {31'b0000000000000000000000000000000,Sum[31]};
    
    //designing 4x1 mux
    assign mux_2 = (ALUControl[2:0] == 3'b000) ? Sum :
                    (ALUControl[2:0] == 3'b001) ? Sum :
                    (ALUControl[2:0] == 3'b010) ? a_and_b :
                    (ALUControl[2:0] == 3'b011) ? a_or_b :
                    (ALUControl[2:0] == 3'b101) ? slt : 32'h00000000;
                    
                
   assign Result = mux_2;
   
   //Flags Assignment 
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]));
    assign Carry = ((~ALUControl[1]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];

endmodule