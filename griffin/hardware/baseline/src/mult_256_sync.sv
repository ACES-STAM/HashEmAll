// Module that performs multiplication between two 256-bit unsigned integers.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 3 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 3 clock cycles.
//     - Accepts new request in every clock cycle.

// WARNING: This code is optimized for devices having 27-by-N-bit DSP units, where N >= 27.
module mult_256_sync (
    input clk,
    input [256-1:0] num1,
    input [256-1:0] num2,
    output [2*256-1:0] product
);

reg [2*256-1:0] partial_product_lo [0:10-1];
reg [2*256-1:0] partial_product_hi [0:10-1];

wire [2*256-1:0] sum_tree_lo [0:11-1];
wire [2*256-1:0] sum_tree_hi [0:11-1];

reg [256-1:0] num1_saved;
reg [256-1:0] num2_saved;
reg [2*256-1:0] sum_tree_lo_saved [0:2-1];

assign sum_tree_lo[6] = partial_product_lo[0] + (partial_product_lo[1] << (27*(2**0)));
assign sum_tree_lo[7] = partial_product_lo[2] + (partial_product_lo[3] << (27*(2**0)));
assign sum_tree_lo[8] = partial_product_lo[4] + (partial_product_lo[5] << (27*(2**0)));
assign sum_tree_lo[9] = partial_product_lo[6] + (partial_product_lo[7] << (27*(2**0)));
assign sum_tree_lo[10] = partial_product_lo[8] + (partial_product_lo[9] << (27*(2**0)));

assign sum_tree_lo[3] = sum_tree_lo[6] + (sum_tree_lo[7] << (27*(2**1)));
assign sum_tree_lo[4] = sum_tree_lo[8] + (sum_tree_lo[9] << (27*(2**1)));
assign sum_tree_lo[5] = sum_tree_lo[10];

assign sum_tree_lo[1] = sum_tree_lo[3] + (sum_tree_lo[4] << (27*(2**2)));
assign sum_tree_lo[2] = sum_tree_lo[5];

assign sum_tree_lo[0] = sum_tree_lo[1] + (sum_tree_lo[2] << (27*(2**3)));

assign sum_tree_hi[6] = partial_product_hi[0] + (partial_product_hi[1] << (27*(2**0)));
assign sum_tree_hi[7] = partial_product_hi[2] + (partial_product_hi[3] << (27*(2**0)));
assign sum_tree_hi[8] = partial_product_hi[4] + (partial_product_hi[5] << (27*(2**0)));
assign sum_tree_hi[9] = partial_product_hi[6] + (partial_product_hi[7] << (27*(2**0)));
assign sum_tree_hi[10] = partial_product_hi[8] + (partial_product_hi[9] << (27*(2**0)));

assign sum_tree_hi[3] = sum_tree_hi[6] + (sum_tree_hi[7] << (27*(2**1)));
assign sum_tree_hi[4] = sum_tree_hi[8] + (sum_tree_hi[9] << (27*(2**1)));
assign sum_tree_hi[5] = sum_tree_hi[10];

assign sum_tree_hi[1] = sum_tree_hi[3] + (sum_tree_hi[4] << (27*(2**2)));
assign sum_tree_hi[2] = sum_tree_hi[5];

assign sum_tree_hi[0] = sum_tree_hi[1] + (sum_tree_hi[2] << (27*(2**3)));

assign product = sum_tree_lo_saved[0] + (sum_tree_hi[0] << 128);

always @(posedge clk) begin
    partial_product_lo[0] <= num1[128*0 +: 128] * num2[27*0 +: 27];
    partial_product_lo[1] <= num1[128*0 +: 128] * num2[27*1 +: 27];
    partial_product_lo[2] <= num1[128*0 +: 128] * num2[27*2 +: 27];
    partial_product_lo[3] <= num1[128*0 +: 128] * num2[27*3 +: 27];
    partial_product_lo[4] <= num1[128*0 +: 128] * num2[27*4 +: 27];
    partial_product_lo[5] <= num1[128*0 +: 128] * num2[27*5 +: 27];
    partial_product_lo[6] <= num1[128*0 +: 128] * num2[27*6 +: 27];
    partial_product_lo[7] <= num1[128*0 +: 128] * num2[27*7 +: 27];
    partial_product_lo[8] <= num1[128*0 +: 128] * num2[27*8 +: 27];
    partial_product_lo[9] <= num1[128*0 +: 128] * num2[27*9 +: 13];

    num1_saved <= num1;
    num2_saved <= num2;

    sum_tree_lo_saved[0] <= sum_tree_lo[0];
    sum_tree_lo_saved[1] <= sum_tree_lo_saved[0];

    partial_product_hi[0] <= num1_saved[128*1 +: 128] * num2_saved[27*0 +: 27];
    partial_product_hi[1] <= num1_saved[128*1 +: 128] * num2_saved[27*1 +: 27];
    partial_product_hi[2] <= num1_saved[128*1 +: 128] * num2_saved[27*2 +: 27];
    partial_product_hi[3] <= num1_saved[128*1 +: 128] * num2_saved[27*3 +: 27];
    partial_product_hi[4] <= num1_saved[128*1 +: 128] * num2_saved[27*4 +: 27];
    partial_product_hi[5] <= num1_saved[128*1 +: 128] * num2_saved[27*5 +: 27];
    partial_product_hi[6] <= num1_saved[128*1 +: 128] * num2_saved[27*6 +: 27];
    partial_product_hi[7] <= num1_saved[128*1 +: 128] * num2_saved[27*7 +: 27];
    partial_product_hi[8] <= num1_saved[128*1 +: 128] * num2_saved[27*8 +: 27];
    partial_product_hi[9] <= num1_saved[128*1 +: 128] * num2_saved[27*9 +: 13];
end

endmodule
