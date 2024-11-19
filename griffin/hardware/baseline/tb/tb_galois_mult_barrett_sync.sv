`timescale 1ns/1ns
module tb_galois_mult_barrett_sync;

    // Parameters
    parameter N_BITS = 254;
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925;

    // Testbench signals
    logic clk;
    logic [N_BITS-1:0] num1;
    logic [N_BITS-1:0] num2;
    logic [N_BITS-1:0] product;

    // Instantiate the DUT (Device Under Test)
    galois_mult_barrett_sync #(
        .N_BITS(N_BITS),
        .PRIME_MODULUS(PRIME_MODULUS),
        .BARRETT_R(BARRETT_R)
    ) dut (
        .clk(clk),
        .num1(num1),
        .num2(num2),
        .product(product)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Clock with 10ns period
    end

    // Input test cases (12 sets of inputs)
    logic [N_BITS-1:0] test_num1 [0:11];
    logic [N_BITS-1:0] test_num2 [0:11];
    logic [N_BITS-1:0] expected_product [0:11];  // Expected results if known

    // Initialize input test vectors
    initial begin
        test_num1[0]  = 254'h1;
        test_num1[1]  = 254'h2;
        test_num1[2]  = 254'h3;
        test_num1[3]  = 254'h4;
        test_num1[4]  = 254'h5;
        test_num1[5]  = 254'h6;
        test_num1[6]  = 254'h7;
        test_num1[7]  = 254'h8;
        test_num1[8]  = 254'h9;
        test_num1[9]  = 254'hA;
        test_num1[10] = 254'hB;
        test_num1[11] = 254'hC;

        test_num2[0]  = 254'hD;
        test_num2[1]  = 254'hE;
        test_num2[2]  = 254'hF;
        test_num2[3]  = 254'h10;
        test_num2[4]  = 254'h11;
        test_num2[5]  = 254'h12;
        test_num2[6]  = 254'h13;
        test_num2[7]  = 254'h14;
        test_num2[8]  = 254'h15;
        test_num2[9]  = 254'h16;
        test_num2[10] = 254'h17;
        test_num2[11] = 254'h18;

        for (int i = 0; i < 12; i++) begin
            expected_product[i] = (test_num1[i] * test_num2[i]) % PRIME_MODULUS;
        end

        // Wait for the DUT to initialize
        #10;
    end

    // Apply inputs to the DUT
    integer i;
    initial begin
        $dumpfile("tb_galois_mult_barrett_sync.vcd");
        $dumpvars(0, tb_galois_mult_barrett_sync);

        // Stimulate the DUT with the 12 input pairs
        for (i = 0; i < 12; i = i + 1) begin
            num1 = test_num1[i];
            num2 = test_num2[i];
            #10;  // Wait 10 time units for each new input
        end
    end

    // Capture results from the pipeline
    initial begin
        // Use $monitor to continuously monitor changes in signals
        $monitor("Time = %0t | Test %0d: num1 = %h, num2 = %h, product = %h, expected = %h", 
                 $time, i, num1, num2, product, expected_product[i]);

        // Finish simulation after enough time for the pipeline to flush
        #300;
        $finish;
    end

endmodule
