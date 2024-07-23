`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2024 16:21:39
// Design Name: 
// Module Name: single_cycle_riscv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//1.program counter
module pc (
    input wire clk,input wire reset,
    input wire [31:0] pc_in,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 0;
        end else begin
            pc_out <= pc_in;
        end
    end
endmodule

//2.instruction memory
module instruction_memory (
    input wire [31:0] addr,
    output reg [31:0] instruction
);
    reg [31:0] mem [0:255]; //256 words of memory  

    initial begin
        // sample instructions to load
        mem[0] = 32'h00000513; // addi x10, x0, 0
        mem[1] = 32'h00400593; // addi x11, x0, 4
        mem[2] = 32'h00b50633; // add x12, x10, x11
        mem[3] = 32'h0076a023; // sw x7, 0(x13)
    end

    always @(*) begin
        instruction = mem[addr[31:2]]; // Word-aligned access
    end
endmodule

// 3. REGISTER FILE
module register_file (
    input wire clk,
    input wire we,          //write enzbled
    input wire [4:0] rs1,   //register source 1
    input wire [4:0] rs2,   //register source 1
    input wire [4:0] rd,    //read destination
    input wire [31:0] wd,   //write data
    output wire [31:0] rd1,  //read data 1
    output wire [31:0] rd2  //read data 2
);
    reg [31:0] registers[0:31];

    // Initialize registers
    initial begin
        registers[0] = 32'b0;
    end

    always @(posedge clk) begin
        if (we) begin
            registers[rd] <= wd;
        end
    end

    assign rd1 = registers[rs1];
    assign rd2 = registers[rs2];
endmodule


//4. ALU 

//a: First 32-bit input operand.
//b: Second 32-bit input operand.
//alu_control: 4-bit control signal that determines the ALU operation.
//result: 32-bit output of the ALU operation.
//zero: 1-bit output that indicates if the result is zero.

module alu (
    input wire [31:0] a,input wire [31:0] b,
    input wire [3:0] alu_control,
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case (alu_control)
            4'b0000: result = a + b;  // ADD
            4'b0001: result = a - b;  // SUB
            4'b0010: result = a & b;  // AND
            4'b0011: result = a | b;  // OR
            4'b0100: result = a ^ b;  // XOR
            4'b0101: result = a << b[4:0];  // logical left shift
            4'b0110: result = a >> b[4:0];  // logical right shift
            4'b0111: result = $signed(a) >>> b[4:0];  // arithmetic right shift
            default: result = 32'b0;
        endcase
    end

    assign zero=(result==32'b0); //zero flag:- sets the zero output to 1 if the result is zero, otherwise it sets it to 0.
endmodule

//5. DATA MEMORY
module data_memory (
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] addr,
    input wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] memory [0:255]; //memory array each of width 32 bits

    always @(posedge clk) begin
        if (mem_write) begin
            memory[addr[31:2]] <= wd;
        end
    end

    assign rd = mem_read ? memory[addr[31:2]] : 32'b0;
endmodule

//6. CONTROL UNIT

//alu_src:- A control signal that determines the source of the ALU's second operand.
//0: The second operand comes from a register.
//1: The second operand is an immediate value (constant from the instruction).

module control_unit (
    input wire [6:0] opcode,
    output reg branch,  //This signal indicates whether a branch instruction is being executed.
    output reg mem_read,//This signal indicates whether a memory read operation should be performed.
    output reg mem_to_reg,//This signal indicates whether the data from memory should be written to a register.
    output reg [3:0] alu_op,//This 4-bit signal specifies the operation that the ALU should perform.
    output reg mem_write,//This signal indicates whether a memory write operation should be performed.
    output reg alu_src,//This signal determines the source of the second operand for the ALU.
    output reg reg_write //This signal indicates whether the result should be written back to a register.
);
    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                alu_op = 4'b0010; // ADD
                mem_write = 0;
                alu_src = 0;
                reg_write = 1;
            end
            7'b0000011: begin // LOAD (I-TYPE)
                branch = 0;
                mem_read = 1;
                mem_to_reg = 1;
                alu_op = 4'b0000; // ADD
                mem_write = 0;
                alu_src = 1;
                reg_write = 1;
            end
            7'b0100011: begin // STORE (I-TYPE)
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                alu_op = 4'b0000; // ADD
                mem_write = 1;
                alu_src = 1;
                reg_write = 0;
            end
            7'b1100011: begin // BRANCH
                branch = 1;
                mem_read = 0;
                mem_to_reg = 0;
                alu_op = 4'b0001; // SUB
                mem_write = 0;
                alu_src = 0;
                reg_write = 0;
            end
            default: begin
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                alu_op = 4'b0000;
                mem_write = 0;
                alu_src = 0;
                reg_write = 0;
            end
        endcase
    end
endmodule




// TOP MODULE
module single_cycle_riscv (
    input wire clk,
    input wire reset
);
    // Wires for connections
    wire [31:0] pc, npc, instruction;
    wire [31:0] alu_result, read_data, write_data;
    wire [31:0] rs1_data, rs2_data;
    wire mem_read, mem_write, alu_src, reg_write, mem_to_reg, branch, zero;

    // Program Counter
    pc PC (
        .clk(clk),
        .reset(reset),
        .pc_in(npc),
        .pc_out(pc)
    );

    // Instruction Memory
    instruction_memory IM (
        .addr(pc),
        .instruction(instruction)
    );

    // Register File
    register_file RF (
        .clk(clk),
        .we(reg_write),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .wd(mem_to_reg ? read_data : alu_result),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    // ALU
    alu ALU (
        .a(rs1_data),
        .b(alu_src ? instruction[31:20] : rs2_data),
        .alu_control(instruction[14:12]),
        .result(alu_result),
        .zero(zero)
    );

    // Data Memory
    data_memory DM (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_result),
        .wd(rs2_data),
        .rd(read_data)
    );

    // Control Unit
    control_unit CU (
        .opcode(instruction[6:0]),
        .branch(branch),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_op(instruction[14:12]),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write)
    );

    // Next PC logic
    assign npc = branch & zero ? pc + {instruction[31:20], 2'b00} : pc + 4;
    //next_pc: Determines the next instruction address based on the branch condition and zero flag. 
    //If the branch condition is met and the zero flag is set, the next PC is the branch target address; 
    //otherwise, it increments by 4 to the next sequential instruction.

endmodule
