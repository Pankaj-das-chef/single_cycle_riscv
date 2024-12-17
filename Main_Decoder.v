`timescale 1ns / 1ps

module Main_Decoder(op,zero,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,ALUOp,PCSrc);
    input zero;
    input [6:0]op;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,PCSrc;
    output [1:0]ImmSrc,ALUOp;
    
    //interim wire
    wire branch;

    assign RegWrite = ((op == 7'b0000011) | (op == 7'b0110011)) ? 1'b1 :1'b0 ;
                                                              
    assign ImmSrc = (op == 7'b0100011) ? 2'b01 : (op == 7'b1100011) ? 2'b10 : 2'b00 ;   
                                         
    assign ALUSrc = ((op == 7'b0000011) | (op == 7'b0100011)) ? 1'b1 :1'b0 ;
                                                            
    assign MemWrite = (op == 7'b0100011) ? 1'b1 :1'b0 ;
                                           
    assign ResultSrc = (op == 7'b0000011) ? 1'b1 :1'b0 ;
                                            
    assign Branch = (op == 7'b1100011) ? 1'b1 : 1'b0 ;
                                        
    assign ALUOp = (op == 7'b0110011) ? 2'b10 :(op == 7'b1100011) ? 2'b01 :2'b00 ;
                   
    assign PCSrc = zero & branch;                                   

endmodule