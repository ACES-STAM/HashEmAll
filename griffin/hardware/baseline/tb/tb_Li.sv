`timescale 1ns / 1ps

module tb_Li;

// Parameters
localparam N_BITS = 254;
localparam PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

// Inputs
reg [4:0] i;
reg [N_BITS-1:0] y0;
reg [N_BITS-1:0] y1;
reg [N_BITS-1:0] x_i;
reg clk;
  logic [253:0] correct;
// Output
wire [N_BITS-1:0] l_i;

// Instantiate the Unit Under Test (UUT)
Li #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS)
) uut (
    .i(i),
    .y0(y0),
    .y1(y1),
    .x_i(x_i),
    .l_i(l_i),
    .clk(clk)
);

// Clock generation
always #5 clk = ~clk;  // Clock period is 10 ns (100 MHz)

initial begin
    // Initialize inputs
    clk = 0;
    i = 0;
    y0 = 0;
    y1 = 0;
    x_i = 0;

    // Initialize testbench file for waveform analysis
    $dumpfile("tb_Li.vcd");
    $dumpvars(0, tb_Li);
    
    // Wait for a global reset
    #10;

    // Single Test Case: Apply test values
    i = 5'd10;  // i = 10
    y0 = 254'h2ba46cf9c581bd589bc862cb2272e90ae6b205f5b3d5428db0ce926117f1e756;
    y1 = 254'h123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0;
    x_i = 254'h2FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  correct = 254'h12b587bd85de02c4f4e57946e42c85b983217f3cdfd312cc5372767c2a2fe841;
    // Wait for 4 clock cycles
    #500;
    $display("Single Test Case: l_i = %h", l_i);
  $display("Correct is %h" , correct);

    // Stop simulation
    $stop;
end

endmodule
