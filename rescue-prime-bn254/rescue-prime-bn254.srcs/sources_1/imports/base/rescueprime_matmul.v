//  @author : Secure, Trusted, and Assured Microelectronics (STAM) Center
//
//  Copyright (i) 2024 STAM Center (SCAI/ASU)
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


// Module that performs Rescue-Prime's MDS matrix multiplication operation (state size = 3, exponent = 5).

// Uses 1 galois mult instance and takes time equivalent to 9 modular multiplications.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 117 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 117 clock cycles.
//     - Accepts new request in each of the first 13 clock cycles in every 117-clock-cycle period.

module rescueprime_matmul #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter PIPELINE_EXTRA_DELAY = 0 // Clock cycles
) (
    input clk,
    input  [N_BITS-1:0] input_elem_1,
    input  [N_BITS-1:0] input_elem_2,
    input  [N_BITS-1:0] input_elem_3,
	output [N_BITS-1:0] output_elem_1,
	output [N_BITS-1:0] output_elem_2,
	output [N_BITS-1:0] output_elem_3,
    output reg ready // Indicates: ready to accept new request in the current clock cycle
);

localparam MULT_LATENCY = 12+1; // Clock cylces
localparam COMPUTE_PHASES = 9*MULT_LATENCY + PIPELINE_EXTRA_DELAY;

reg [$clog2(COMPUTE_PHASES)-1:0] compute_phase = PIPELINE_EXTRA_DELAY ? (COMPUTE_PHASES - PIPELINE_EXTRA_DELAY) : 0;

reg [N_BITS-1:0] mult_num1;
reg [N_BITS-1:0] mult_num2;
wire [N_BITS-1:0] mult_product;

reg [N_BITS-1:0] partial_product_matrix [0:9-1][0:MULT_LATENCY-1];

// Memory region for storing Rescue-Prime MDS matrix elements
reg [N_BITS-1:0] memory_mds_matrix [0:9-1];

// Loading of Rescue-Prime MDS matrix
initial begin
	$readmemh("../data/rescue_prime_bn254_mds_matrix.txt", memory_mds_matrix);
end

integer i, j;

// Operation logic
always @(posedge clk) begin
    compute_phase <= (compute_phase + 1'b1) % COMPUTE_PHASES;

	for (i = 1; i < MULT_LATENCY; i = i + 1) begin
		for (j = 0; j < 9; j = j + 1) begin
			partial_product_matrix[j][i] <= partial_product_matrix[j][i-1];
		end
	end
	for (j = 0; j < 9; j = j + 1) begin
		partial_product_matrix[j][0] <= partial_product_matrix[j][MULT_LATENCY-1];
	end

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
		partial_product_matrix[0][0] <= input_elem_1;
        partial_product_matrix[1][0] <= input_elem_2;
        partial_product_matrix[2][0] <= input_elem_3;
		partial_product_matrix[3][0] <= input_elem_1;
        partial_product_matrix[4][0] <= input_elem_2;
        partial_product_matrix[5][0] <= input_elem_3;
		partial_product_matrix[6][0] <= input_elem_1;
        partial_product_matrix[7][0] <= input_elem_2;
		partial_product_matrix[8][0] <= input_elem_3;

		mult_num1 <= input_elem_1;
		mult_num2 <= memory_mds_matrix[0];
	end else if (MULT_LATENCY <= compute_phase && compute_phase <= 2*MULT_LATENCY - 1) begin
		partial_product_matrix[0][0] <= mult_product;

		mult_num1 <= partial_product_matrix[1][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[1];
	end else if (2*MULT_LATENCY <= compute_phase && compute_phase <= 3*MULT_LATENCY - 1) begin
		partial_product_matrix[1][0] <= mult_product;

		mult_num1 <= partial_product_matrix[2][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[2];
	end else if (3*MULT_LATENCY <= compute_phase && compute_phase <= 4*MULT_LATENCY - 1) begin
		partial_product_matrix[2][0] <= mult_product;

		mult_num1 <= partial_product_matrix[3][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[3];
	end else if (4*MULT_LATENCY <= compute_phase && compute_phase <= 5*MULT_LATENCY - 1) begin
		partial_product_matrix[3][0] <= mult_product;

		mult_num1 <= partial_product_matrix[4][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[4];
	end else if (5*MULT_LATENCY <= compute_phase && compute_phase <= 6*MULT_LATENCY - 1) begin
		partial_product_matrix[4][0] <= mult_product;

		mult_num1 <= partial_product_matrix[5][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[5];
	end else if (6*MULT_LATENCY <= compute_phase && compute_phase <= 7*MULT_LATENCY - 1) begin
		partial_product_matrix[5][0] <= mult_product;

		mult_num1 <= partial_product_matrix[6][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[6];
	end else if (7*MULT_LATENCY <= compute_phase && compute_phase <= 8*MULT_LATENCY - 1) begin
		partial_product_matrix[6][0] <= mult_product;

		mult_num1 <= partial_product_matrix[7][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[7];
	end else if (8*MULT_LATENCY <= compute_phase && compute_phase <= 9*MULT_LATENCY - 1) begin
		partial_product_matrix[7][0] <= mult_product;

		mult_num1 <= partial_product_matrix[8][MULT_LATENCY-1];
		mult_num2 <= memory_mds_matrix[8];
	end

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
		ready <= 1'b1;
	end else begin
		ready <= 1'b0;
	end
end

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT (
	.clk(clk),
	.num1(mult_num1),
	.num2(mult_num2),
	.product(mult_product)
);

galois_add_three #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_1 (
	.num1(partial_product_matrix[0][MULT_LATENCY-1]),
	.num2(partial_product_matrix[1][MULT_LATENCY-1]),
	.num3(partial_product_matrix[2][MULT_LATENCY-1]),
	.sum(output_elem_1)
);

galois_add_three #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_2 (
	.num1(partial_product_matrix[3][MULT_LATENCY-1]),
	.num2(partial_product_matrix[4][MULT_LATENCY-1]),
	.num3(partial_product_matrix[5][MULT_LATENCY-1]),
	.sum(output_elem_2)
);

galois_add_three #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_3 (
	.num1(partial_product_matrix[6][MULT_LATENCY-1]),
	.num2(partial_product_matrix[7][MULT_LATENCY-1]),
	.num3(mult_product),
	.sum(output_elem_3)
);

endmodule
