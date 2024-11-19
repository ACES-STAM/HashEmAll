//  @author : Secure, Trusted, and Assured Microelectronics (STAM) Center
//
//  Copyright (c) 2024 STAM Center (SCAI/ASU)
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


// Module that performs multiplication between two 256-bit unsigned integers.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 3 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 3 clock cycles.
//     - Accepts new request in every clock cycle.

// WARNING: This code is optimized for devices having 16-by-N-bit DSP units, where N >= 16.

module mult_256_sync (
    input clk,
    input [256-1:0] num1,
    input [256-1:0] num2,
    output [2*256-1:0] product
);

reg [2*256-1:0] partial_product_lo [0:16-1];
reg [2*256-1:0] partial_product_hi [0:16-1];

wire [2*256-1:0] sum_tree_lo [0:15-1];
wire [2*256-1:0] sum_tree_hi [0:15-1];

reg [256-1:0] num1_saved;
reg [256-1:0] num2_saved;
reg [2*256-1:0] sum_tree_lo_saved [0:2-1];

assign sum_tree_lo[7] = partial_product_lo[0] + (partial_product_lo[1] << (16*1));
assign sum_tree_lo[8] = partial_product_lo[2] + (partial_product_lo[3] << (16*1));
assign sum_tree_lo[9] = partial_product_lo[4] + (partial_product_lo[5] << (16*1));
assign sum_tree_lo[10] = partial_product_lo[6] + (partial_product_lo[7] << (16*1));
assign sum_tree_lo[11] = partial_product_lo[8] + (partial_product_lo[9] << (16*1));
assign sum_tree_lo[12] = partial_product_lo[10] + (partial_product_lo[11] << (16*1));
assign sum_tree_lo[13] = partial_product_lo[12] + (partial_product_lo[13] << (16*1));
assign sum_tree_lo[14] = partial_product_lo[14] + (partial_product_lo[15] << (16*1));

assign sum_tree_lo[3] = sum_tree_lo[7] + (sum_tree_lo[8] << (16*2));
assign sum_tree_lo[4] = sum_tree_lo[9] + (sum_tree_lo[10] << (16*2));
assign sum_tree_lo[5] = sum_tree_lo[11] + (sum_tree_lo[12] << (16*2));
assign sum_tree_lo[6] = sum_tree_lo[13] + (sum_tree_lo[14] << (16*2));

assign sum_tree_lo[1] = sum_tree_lo[3] + (sum_tree_lo[4] << (16*4));
assign sum_tree_lo[2] = sum_tree_lo[5] + (sum_tree_lo[6] << (16*4));

assign sum_tree_lo[0] = sum_tree_lo[1] + (sum_tree_lo[2] << (16*8));

assign sum_tree_hi[7] = partial_product_hi[0] + (partial_product_hi[1] << (16*1));
assign sum_tree_hi[8] = partial_product_hi[2] + (partial_product_hi[3] << (16*1));
assign sum_tree_hi[9] = partial_product_hi[4] + (partial_product_hi[5] << (16*1));
assign sum_tree_hi[10] = partial_product_hi[6] + (partial_product_hi[7] << (16*1));
assign sum_tree_hi[11] = partial_product_hi[8] + (partial_product_hi[9] << (16*1));
assign sum_tree_hi[12] = partial_product_hi[10] + (partial_product_hi[11] << (16*1));
assign sum_tree_hi[13] = partial_product_hi[12] + (partial_product_hi[13] << (16*1));
assign sum_tree_hi[14] = partial_product_hi[14] + (partial_product_hi[15] << (16*1));

assign sum_tree_hi[3] = sum_tree_hi[7] + (sum_tree_hi[8] << (16*2));
assign sum_tree_hi[4] = sum_tree_hi[9] + (sum_tree_hi[10] << (16*2));
assign sum_tree_hi[5] = sum_tree_hi[11] + (sum_tree_hi[12] << (16*2));
assign sum_tree_hi[6] = sum_tree_hi[13] + (sum_tree_hi[14] << (16*2));

assign sum_tree_hi[1] = sum_tree_hi[3] + (sum_tree_hi[4] << (16*4));
assign sum_tree_hi[2] = sum_tree_hi[5] + (sum_tree_hi[6] << (16*4));

assign sum_tree_hi[0] = sum_tree_hi[1] + (sum_tree_hi[2] << (16*8));

assign product = sum_tree_lo_saved[0] + (sum_tree_hi[0] << 128);

// Operation logic
always @(posedge clk) begin
    partial_product_lo[0] <= num1[128*0 +: 128] * num2[16*0 +: 16];
    partial_product_lo[1] <= num1[128*0 +: 128] * num2[16*1 +: 16];
    partial_product_lo[2] <= num1[128*0 +: 128] * num2[16*2 +: 16];
    partial_product_lo[3] <= num1[128*0 +: 128] * num2[16*3 +: 16];
    partial_product_lo[4] <= num1[128*0 +: 128] * num2[16*4 +: 16];
    partial_product_lo[5] <= num1[128*0 +: 128] * num2[16*5 +: 16];
    partial_product_lo[6] <= num1[128*0 +: 128] * num2[16*6 +: 16];
    partial_product_lo[7] <= num1[128*0 +: 128] * num2[16*7 +: 16];
    partial_product_lo[8] <= num1[128*0 +: 128] * num2[16*8 +: 16];
    partial_product_lo[9] <= num1[128*0 +: 128] * num2[16*9 +: 16];
    partial_product_lo[10] <= num1[128*0 +: 128] * num2[16*10 +: 16];
    partial_product_lo[11] <= num1[128*0 +: 128] * num2[16*11 +: 16];
    partial_product_lo[12] <= num1[128*0 +: 128] * num2[16*12 +: 16];
    partial_product_lo[13] <= num1[128*0 +: 128] * num2[16*13 +: 16];
    partial_product_lo[14] <= num1[128*0 +: 128] * num2[16*14 +: 16];
    partial_product_lo[15] <= num1[128*0 +: 128] * num2[16*15 +: 16];

    num1_saved <= num1;
    num2_saved <= num2;

    sum_tree_lo_saved[0] <= sum_tree_lo[0];
    sum_tree_lo_saved[1] <= sum_tree_lo_saved[0];

    partial_product_hi[0] <= num1_saved[128*1 +: 128] * num2_saved[16*0 +: 16];
    partial_product_hi[1] <= num1_saved[128*1 +: 128] * num2_saved[16*1 +: 16];
    partial_product_hi[2] <= num1_saved[128*1 +: 128] * num2_saved[16*2 +: 16];
    partial_product_hi[3] <= num1_saved[128*1 +: 128] * num2_saved[16*3 +: 16];
    partial_product_hi[4] <= num1_saved[128*1 +: 128] * num2_saved[16*4 +: 16];
    partial_product_hi[5] <= num1_saved[128*1 +: 128] * num2_saved[16*5 +: 16];
    partial_product_hi[6] <= num1_saved[128*1 +: 128] * num2_saved[16*6 +: 16];
    partial_product_hi[7] <= num1_saved[128*1 +: 128] * num2_saved[16*7 +: 16];
    partial_product_hi[8] <= num1_saved[128*1 +: 128] * num2_saved[16*8 +: 16];
    partial_product_hi[9] <= num1_saved[128*1 +: 128] * num2_saved[16*9 +: 16];
    partial_product_hi[10] <= num1_saved[128*1 +: 128] * num2_saved[16*10 +: 16];
    partial_product_hi[11] <= num1_saved[128*1 +: 128] * num2_saved[16*11 +: 16];
    partial_product_hi[12] <= num1_saved[128*1 +: 128] * num2_saved[16*12 +: 16];
    partial_product_hi[13] <= num1_saved[128*1 +: 128] * num2_saved[16*13 +: 16];
    partial_product_hi[14] <= num1_saved[128*1 +: 128] * num2_saved[16*14 +: 16];
    partial_product_hi[15] <= num1_saved[128*1 +: 128] * num2_saved[16*15 +: 16];
end

endmodule
