module tb_single_cycle_riscv;

    reg clk;
    reg reset;

    single_cycle_riscv uut (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;

        // Reset the processor
        #10 reset = 0;

        // Run the simulation
        #100 $finish;
    end

    // Clock generation
    always #5 clk = ~clk;

endmodule
