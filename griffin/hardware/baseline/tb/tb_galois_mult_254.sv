`timescale 1ns / 1ps

module tb_galois_mult_254;

// Inputs
reg clk;
reg [4:0] num1;
  reg [253:0] num2;
reg PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
// Outputs
  wire [253:0] product;
  reg [258:0] correct;

// Instantiate the Unit Under Test (UUT)
galois_mult_254 uut (
    .clk(clk),
    .num1(num1),
    .num2(num2),
    .result(product)
);
always #5 clk = ~clk;  // 10 ns clock period (100 MHz)

initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, tb_galois_mult_254);
    // Initialize inputs
    clk = 0;
    num1 = 0;
    num2 = 0;
    
    // Wait for the global reset
    #10;
    
    // Test case: num1 = 3, num2 = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    num1 = 5'd23;  // 3 in binary
      num2 =254'h290877c6917e71668768241b2a306a0bcebd91a60aa18177727bbb54d3cc914d; 	
  correct = num1 * num2;

    // Wait for 2 cycles (multiplication and summation)
    #100; // Wait for 4 cycles (2 cycles for the pipeline to process multiplication and addition)
  $display("actual is %h, expected is %h", product, correct);
    
    // Stop the simulation
    $stop;
end

endmodule
