
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


// Module that performs one round of Rescue-Prime (state size = 3, exponent = 5).

// WARNING: Currently only works for for BN-254 field; hardcoded values.
// WARNING: Currently assumes that inverse exponent is an odd integer; hardcoded logic.

// Uses 3 galois mult instances and takes time equivalent to 401 modular multiplications.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 5213 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 5213 clock cycles.
//     - Accepts new request in each of the first 13 clock cycles in every 5213-clock-cycle period.

module rescueprime_round_3x #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
	parameter RESCUE_INV_EXP = 254'h26B6A528B427B35493736AF8679AAD17535CB9D394945A0DCFE7F7A98CCCCCCD, // Size: N_BITS
    parameter PIPELINE_EXTRA_DELAY = 0 // Clock cycles
) (
    input clk,
    input  [N_BITS-1:0] input_elem_1,
    input  [N_BITS-1:0] input_elem_2,
    input  [N_BITS-1:0] input_elem_3,
    input  [N_BITS-1:0] round_const_1_elem_1,
    input  [N_BITS-1:0] round_const_1_elem_2,
    input  [N_BITS-1:0] round_const_1_elem_3,
    input  [N_BITS-1:0] round_const_2_elem_1,
    input  [N_BITS-1:0] round_const_2_elem_2,
    input  [N_BITS-1:0] round_const_2_elem_3,
	output [N_BITS-1:0] output_elem_1,
	output [N_BITS-1:0] output_elem_2,
	output [N_BITS-1:0] output_elem_3,
    output reg ready // Indicates: ready to accept new request in the current clock cycle
);

localparam MULT_LATENCY = 12+1; // Clock cylces
localparam COMPUTE_PHASES = 401*MULT_LATENCY + PIPELINE_EXTRA_DELAY;
localparam DELAYED_OUTPUT_LATENCY = 12; // Clock cycles

reg [$clog2(COMPUTE_PHASES)-1:0] compute_phase = PIPELINE_EXTRA_DELAY ? (COMPUTE_PHASES - PIPELINE_EXTRA_DELAY) : 0;

reg [N_BITS-1:0] state [0:3-1][0:MULT_LATENCY-1];
reg [N_BITS-1:0] round_constants_1 [0:3-1][0:MULT_LATENCY-1];
reg [N_BITS-1:0] round_constants_2 [0:3-1][0:MULT_LATENCY-1];

reg [N_BITS-1:0] partial_product_matrix [0:9-1][0:MULT_LATENCY-1];

reg [N_BITS-1:0] delayed_outputs [0:3-1][0:DELAYED_OUTPUT_LATENCY-1];

reg [N_BITS-1:0] pow_n [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow_n_new [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow1_x [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow1_y [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow2_x [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow2_y [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow3_x [0:MULT_LATENCY-1];
reg [N_BITS-1:0] pow3_y [0:MULT_LATENCY-1];

reg [N_BITS-1:0] mult1_num1;
reg [N_BITS-1:0] mult1_num2;
wire [N_BITS-1:0] mult1_product;

reg [N_BITS-1:0] mult2_num1;
reg [N_BITS-1:0] mult2_num2;
wire [N_BITS-1:0] mult2_product;

reg [N_BITS-1:0] mult3_num1;
reg [N_BITS-1:0] mult3_num2;
wire [N_BITS-1:0] mult3_product;

reg  [N_BITS-1:0] addthree1_num1;
reg  [N_BITS-1:0] addthree1_num2;
reg  [N_BITS-1:0] addthree1_num3;
wire [N_BITS-1:0] addthree1_sum;

reg  [N_BITS-1:0] addthree2_num1;
reg  [N_BITS-1:0] addthree2_num2;
reg  [N_BITS-1:0] addthree2_num3;
wire [N_BITS-1:0] addthree2_sum;

reg  [N_BITS-1:0] addthree3_num1;
reg  [N_BITS-1:0] addthree3_num2;
reg  [N_BITS-1:0] addthree3_num3;
wire [N_BITS-1:0] addthree3_sum;

reg  [N_BITS-1:0] add1_num1;
reg  [N_BITS-1:0] add1_num2;
wire [N_BITS-1:0] add1_sum;

reg  [N_BITS-1:0] add2_num1;
reg  [N_BITS-1:0] add2_num2;
wire [N_BITS-1:0] add2_sum;

reg  [N_BITS-1:0] add3_num1;
reg  [N_BITS-1:0] add3_num2;
wire [N_BITS-1:0] add3_sum;

// Memory region for storing Rescue-Prime MDS matrix elements
reg [N_BITS-1:0] memory_mds_matrix [0:3*3-1];

// Loading of Rescue-Prime MDS matrix
initial begin
	$readmemh("../data/rescue_prime_bn254_mds_matrix.txt", memory_mds_matrix);
end

integer i, j;

// Operation logic
always @(posedge clk) begin
    compute_phase <= (compute_phase + 1'b1) % COMPUTE_PHASES;

	if (0 <= compute_phase && compute_phase < MULT_LATENCY) begin
		state[0][compute_phase] <= input_elem_1;
        state[1][compute_phase] <= input_elem_2;
        state[2][compute_phase] <= input_elem_3;
		round_constants_1[0][compute_phase] <= round_const_1_elem_1;
        round_constants_1[1][compute_phase] <= round_const_1_elem_2;
        round_constants_1[2][compute_phase] <= round_const_1_elem_3;
		round_constants_2[0][compute_phase] <= round_const_2_elem_1;
        round_constants_2[1][compute_phase] <= round_const_2_elem_2;
        round_constants_2[2][compute_phase] <= round_const_2_elem_3;

		mult1_num1 <= input_elem_1;
		mult1_num2 <= input_elem_1;

		mult2_num1 <= input_elem_2;
		mult2_num2 <= input_elem_2;

		mult3_num1 <= input_elem_3;
		mult3_num2 <= input_elem_3;
	end else if (MULT_LATENCY <= compute_phase && compute_phase < 2*MULT_LATENCY) begin
		mult1_num1 <= mult1_product;
		mult1_num2 <= mult1_product;

		mult2_num1 <= mult2_product;
		mult2_num2 <= mult2_product;

		mult3_num1 <= mult3_product;
		mult3_num2 <= mult3_product;
	end else if (2*MULT_LATENCY <= compute_phase && compute_phase < 3*MULT_LATENCY) begin
		mult1_num1 <= mult1_product;
		mult1_num2 <= state[0][compute_phase - 2*MULT_LATENCY];

		mult2_num1 <= mult2_product;
		mult2_num2 <= state[1][compute_phase - 2*MULT_LATENCY];

		mult3_num1 <= mult3_product;
		mult3_num2 <= state[2][compute_phase - 2*MULT_LATENCY];
	end else if (3*MULT_LATENCY <= compute_phase && compute_phase < 4*MULT_LATENCY) begin
		state[0][compute_phase - 3*MULT_LATENCY] <= mult1_product;
		state[1][compute_phase - 3*MULT_LATENCY] <= mult2_product;
		state[2][compute_phase - 3*MULT_LATENCY] <= mult3_product;

		mult1_num1 <= mult1_product;
		mult1_num2 <= memory_mds_matrix[0];

		mult2_num1 <= mult2_product;
		mult2_num2 <= memory_mds_matrix[1];

		mult3_num1 <= mult3_product;
		mult3_num2 <= memory_mds_matrix[2];
	end else if (4*MULT_LATENCY <= compute_phase && compute_phase < 5*MULT_LATENCY) begin
		partial_product_matrix[0][compute_phase - 4*MULT_LATENCY] <= mult1_product;
		partial_product_matrix[1][compute_phase - 4*MULT_LATENCY] <= mult2_product;
		partial_product_matrix[2][compute_phase - 4*MULT_LATENCY] <= mult3_product;

		mult1_num1 <= state[0][compute_phase - 4*MULT_LATENCY];
		mult1_num2 <= memory_mds_matrix[3];

		mult2_num1 <= state[1][compute_phase - 4*MULT_LATENCY];
		mult2_num2 <= memory_mds_matrix[4];

		mult3_num1 <= state[2][compute_phase - 4*MULT_LATENCY];
		mult3_num2 <= memory_mds_matrix[5];
	end else if (5*MULT_LATENCY <= compute_phase && compute_phase < 6*MULT_LATENCY) begin
		partial_product_matrix[3][compute_phase - 5*MULT_LATENCY] <= mult1_product;
		partial_product_matrix[4][compute_phase - 5*MULT_LATENCY] <= mult2_product;
		partial_product_matrix[5][compute_phase - 5*MULT_LATENCY] <= mult3_product;

		mult1_num1 <= state[0][compute_phase - 5*MULT_LATENCY];
		mult1_num2 <= memory_mds_matrix[6];

		mult2_num1 <= state[1][compute_phase - 5*MULT_LATENCY];
		mult2_num2 <= memory_mds_matrix[7];

		mult3_num1 <= state[2][compute_phase - 5*MULT_LATENCY];
		mult3_num2 <= memory_mds_matrix[8];
	end else if (6*MULT_LATENCY <= compute_phase && compute_phase < 7*MULT_LATENCY) begin
		partial_product_matrix[6][compute_phase - 6*MULT_LATENCY] <= mult1_product;
		partial_product_matrix[7][compute_phase - 6*MULT_LATENCY] <= mult2_product;
		partial_product_matrix[8][compute_phase - 6*MULT_LATENCY] <= mult3_product;

		addthree1_num1 <= partial_product_matrix[0][compute_phase - 6*MULT_LATENCY];
		addthree1_num2 <= partial_product_matrix[1][compute_phase - 6*MULT_LATENCY];
		addthree1_num3 <= partial_product_matrix[2][compute_phase - 6*MULT_LATENCY];

		addthree2_num1 <= partial_product_matrix[3][compute_phase - 6*MULT_LATENCY];
		addthree2_num2 <= partial_product_matrix[4][compute_phase - 6*MULT_LATENCY];
		addthree2_num3 <= partial_product_matrix[5][compute_phase - 6*MULT_LATENCY];

		addthree3_num1 <= mult1_product;
		addthree3_num2 <= mult2_product;
		addthree3_num3 <= mult3_product;

		if (6*MULT_LATENCY != compute_phase) begin
			state[0][compute_phase - 1 - 6*MULT_LATENCY] <= addthree1_sum;
			state[1][compute_phase - 1 - 6*MULT_LATENCY] <= addthree2_sum;
			state[2][compute_phase - 1 - 6*MULT_LATENCY] <= addthree3_sum;
		end
	end else if (7*MULT_LATENCY <= compute_phase && compute_phase < 8*MULT_LATENCY) begin
		if (7*MULT_LATENCY == compute_phase) begin
			state[0][compute_phase - 1 - 6*MULT_LATENCY] <= addthree1_sum;
			state[1][compute_phase - 1 - 6*MULT_LATENCY] <= addthree2_sum;
			state[2][compute_phase - 1 - 6*MULT_LATENCY] <= addthree3_sum;
		end

		add1_num1 <= state[0][compute_phase - 7*MULT_LATENCY];
		add1_num2 <= round_constants_1[0][compute_phase - 7*MULT_LATENCY];

		add2_num1 <= state[1][compute_phase - 7*MULT_LATENCY];
		add2_num2 <= round_constants_1[1][compute_phase - 7*MULT_LATENCY];

		add3_num1 <= state[2][compute_phase - 7*MULT_LATENCY];
		add3_num2 <= round_constants_1[2][compute_phase - 7*MULT_LATENCY];

		if (7*MULT_LATENCY != compute_phase) begin
			state[0][compute_phase - 1 - 7*MULT_LATENCY] <= add1_sum;
			state[1][compute_phase - 1 - 7*MULT_LATENCY] <= add2_sum;
			state[2][compute_phase - 1 - 7*MULT_LATENCY] <= add3_sum;
		end
	end else if (8*MULT_LATENCY <= compute_phase && compute_phase < 9*MULT_LATENCY) begin
		if (8*MULT_LATENCY == compute_phase) begin
			state[0][compute_phase - 1 - 7*MULT_LATENCY] <= add1_sum;
			state[1][compute_phase - 1 - 7*MULT_LATENCY] <= add2_sum;
			state[2][compute_phase - 1 - 7*MULT_LATENCY] <= add3_sum;
		end

		pow_n[compute_phase - 8*MULT_LATENCY] <= RESCUE_INV_EXP - 'b1;
        pow_n_new[compute_phase - 8*MULT_LATENCY] <= (RESCUE_INV_EXP - 'b1) >> 1;

		pow1_x[compute_phase - 8*MULT_LATENCY] <= state[0][compute_phase - 8*MULT_LATENCY];
        pow1_y[compute_phase - 8*MULT_LATENCY] <= state[0][compute_phase - 8*MULT_LATENCY];

		pow2_x[compute_phase - 8*MULT_LATENCY] <= state[1][compute_phase - 8*MULT_LATENCY];
        pow2_y[compute_phase - 8*MULT_LATENCY] <= state[1][compute_phase - 8*MULT_LATENCY];

		pow3_x[compute_phase - 8*MULT_LATENCY] <= state[2][compute_phase - 8*MULT_LATENCY];
		pow3_y[compute_phase - 8*MULT_LATENCY] <= state[2][compute_phase - 8*MULT_LATENCY];

		mult1_num1 <= state[0][compute_phase - 8*MULT_LATENCY];
		mult1_num2 <= state[0][compute_phase - 8*MULT_LATENCY];

		mult2_num1 <= state[1][compute_phase - 8*MULT_LATENCY];
		mult2_num2 <= state[1][compute_phase - 8*MULT_LATENCY];

		mult3_num1 <= state[2][compute_phase - 8*MULT_LATENCY];
		mult3_num2 <= state[2][compute_phase - 8*MULT_LATENCY];
	end else if (9*MULT_LATENCY <= compute_phase && compute_phase < 396*MULT_LATENCY) begin
		pow_n[compute_phase % MULT_LATENCY] <= pow_n_new[compute_phase % MULT_LATENCY];

		if (pow_n[compute_phase % MULT_LATENCY] & 'b1) begin
			pow_n_new[compute_phase % MULT_LATENCY] <= pow_n_new[compute_phase % MULT_LATENCY] >> 1;

			pow1_y[compute_phase % MULT_LATENCY] <= mult1_product;
			pow2_y[compute_phase % MULT_LATENCY] <= mult2_product;
			pow3_y[compute_phase % MULT_LATENCY] <= mult3_product;

			mult1_num1 <= pow1_x[compute_phase % MULT_LATENCY];
			mult1_num2 <= pow1_x[compute_phase % MULT_LATENCY];

			mult2_num1 <= pow2_x[compute_phase % MULT_LATENCY];
			mult2_num2 <= pow2_x[compute_phase % MULT_LATENCY];

			mult3_num1 <= pow3_x[compute_phase % MULT_LATENCY];
			mult3_num2 <= pow3_x[compute_phase % MULT_LATENCY];
		end else begin
			pow1_x[compute_phase % MULT_LATENCY] <= mult1_product;
			pow2_x[compute_phase % MULT_LATENCY] <= mult2_product;
			pow3_x[compute_phase % MULT_LATENCY] <= mult3_product;

			if (pow_n_new[compute_phase % MULT_LATENCY] & 'b1) begin
				pow_n_new[compute_phase % MULT_LATENCY] <= pow_n_new[compute_phase % MULT_LATENCY] - 'b1;

				mult1_num1 <= mult1_product;
				mult1_num2 <= pow1_y[compute_phase % MULT_LATENCY];

				mult2_num1 <= mult2_product;
				mult2_num2 <= pow2_y[compute_phase % MULT_LATENCY];

				mult3_num1 <= mult3_product;
				mult3_num2 <= pow3_y[compute_phase % MULT_LATENCY];
			end else begin
				pow_n_new[compute_phase % MULT_LATENCY] <= pow_n_new[compute_phase % MULT_LATENCY] >> 1;

				mult1_num1 <= mult1_product;
				mult1_num2 <= mult1_product;

				mult2_num1 <= mult2_product;
				mult2_num2 <= mult2_product;

				mult3_num1 <= mult3_product;
				mult3_num2 <= mult3_product;
			end
		end
	end else if (396*MULT_LATENCY <= compute_phase && compute_phase < 397*MULT_LATENCY) begin
		state[0][compute_phase - 396*MULT_LATENCY] <= mult1_product;
		state[1][compute_phase - 396*MULT_LATENCY] <= mult2_product;
		state[2][compute_phase - 396*MULT_LATENCY] <= mult3_product;

		mult1_num1 <= mult1_product;
		mult1_num2 <= memory_mds_matrix[0];

		mult2_num1 <= mult2_product;
		mult2_num2 <= memory_mds_matrix[1];

		mult3_num1 <= mult3_product;
		mult3_num2 <= memory_mds_matrix[2];
	end else if (397*MULT_LATENCY <= compute_phase && compute_phase < 398*MULT_LATENCY) begin
		partial_product_matrix[0][compute_phase - 397*MULT_LATENCY] <= mult1_product;
		partial_product_matrix[1][compute_phase - 397*MULT_LATENCY] <= mult2_product;
		partial_product_matrix[2][compute_phase - 397*MULT_LATENCY] <= mult3_product;

		mult1_num1 <= state[0][compute_phase - 397*MULT_LATENCY];
		mult1_num2 <= memory_mds_matrix[3];

		mult2_num1 <= state[1][compute_phase - 397*MULT_LATENCY];
		mult2_num2 <= memory_mds_matrix[4];

		mult3_num1 <= state[2][compute_phase - 397*MULT_LATENCY];
		mult3_num2 <= memory_mds_matrix[5];
	end else if (398*MULT_LATENCY <= compute_phase && compute_phase < 399*MULT_LATENCY) begin
		partial_product_matrix[3][compute_phase - 398*MULT_LATENCY] <= mult1_product;
		partial_product_matrix[4][compute_phase - 398*MULT_LATENCY] <= mult2_product;
		partial_product_matrix[5][compute_phase - 398*MULT_LATENCY] <= mult3_product;

		mult1_num1 <= state[0][compute_phase - 398*MULT_LATENCY];
		mult1_num2 <= memory_mds_matrix[6];

		mult2_num1 <= state[1][compute_phase - 398*MULT_LATENCY];
		mult2_num2 <= memory_mds_matrix[7];

		mult3_num1 <= state[2][compute_phase - 398*MULT_LATENCY];
		mult3_num2 <= memory_mds_matrix[8];
	end else if (399*MULT_LATENCY <= compute_phase && compute_phase < 400*MULT_LATENCY) begin
		partial_product_matrix[6][compute_phase - 399*MULT_LATENCY] <= mult1_product;
		partial_product_matrix[7][compute_phase - 399*MULT_LATENCY] <= mult2_product;
		partial_product_matrix[8][compute_phase - 399*MULT_LATENCY] <= mult3_product;

		addthree1_num1 <= partial_product_matrix[0][compute_phase - 399*MULT_LATENCY];
		addthree1_num2 <= partial_product_matrix[1][compute_phase - 399*MULT_LATENCY];
		addthree1_num3 <= partial_product_matrix[2][compute_phase - 399*MULT_LATENCY];

		addthree2_num1 <= partial_product_matrix[3][compute_phase - 399*MULT_LATENCY];
		addthree2_num2 <= partial_product_matrix[4][compute_phase - 399*MULT_LATENCY];
		addthree2_num3 <= partial_product_matrix[5][compute_phase - 399*MULT_LATENCY];

		addthree3_num1 <= mult1_product;
		addthree3_num2 <= mult2_product;
		addthree3_num3 <= mult3_product;

		if (399*MULT_LATENCY != compute_phase) begin
			state[0][compute_phase - 1 - 399*MULT_LATENCY] <= addthree1_sum;
			state[1][compute_phase - 1 - 399*MULT_LATENCY] <= addthree2_sum;
			state[2][compute_phase - 1 - 399*MULT_LATENCY] <= addthree3_sum;
		end
	end else if (400*MULT_LATENCY <= compute_phase && compute_phase < 401*MULT_LATENCY) begin
		if (400*MULT_LATENCY == compute_phase) begin
			state[0][compute_phase - 1 - 399*MULT_LATENCY] <= addthree1_sum;
			state[1][compute_phase - 1 - 399*MULT_LATENCY] <= addthree2_sum;
			state[2][compute_phase - 1 - 399*MULT_LATENCY] <= addthree3_sum;
		end

		add1_num1 <= state[0][compute_phase - 400*MULT_LATENCY];
		add1_num2 <= round_constants_2[0][compute_phase - 400*MULT_LATENCY];

		add2_num1 <= state[1][compute_phase - 400*MULT_LATENCY];
		add2_num2 <= round_constants_2[1][compute_phase - 400*MULT_LATENCY];

		add3_num1 <= state[2][compute_phase - 400*MULT_LATENCY];
		add3_num2 <= round_constants_2[2][compute_phase - 400*MULT_LATENCY];

		if (400*MULT_LATENCY != compute_phase) begin
			state[0][compute_phase - 1 - 400*MULT_LATENCY] <= add1_sum;
			state[1][compute_phase - 1 - 400*MULT_LATENCY] <= add2_sum;
			state[2][compute_phase - 1 - 400*MULT_LATENCY] <= add3_sum;

			delayed_outputs[0][DELAYED_OUTPUT_LATENCY - 1] <= add1_sum;
			delayed_outputs[1][DELAYED_OUTPUT_LATENCY - 1] <= add2_sum;
			delayed_outputs[2][DELAYED_OUTPUT_LATENCY - 1] <= add3_sum;
		end
	end
	if (PIPELINE_EXTRA_DELAY > 0 && 401*MULT_LATENCY == compute_phase ||
		PIPELINE_EXTRA_DELAY == 0 && 0 == compute_phase
	) begin
			state[0][MULT_LATENCY - 1] <= add1_sum;
			state[1][MULT_LATENCY - 1] <= add2_sum;
			state[2][MULT_LATENCY - 1] <= add3_sum;

			delayed_outputs[0][DELAYED_OUTPUT_LATENCY - 1] <= add1_sum;
			delayed_outputs[1][DELAYED_OUTPUT_LATENCY - 1] <= add2_sum;
			delayed_outputs[2][DELAYED_OUTPUT_LATENCY - 1] <= add3_sum;
	end

	for (i = 1; i < DELAYED_OUTPUT_LATENCY; i = i + 1) begin
		for (j = 0; j < 3; j = j + 1) begin
			delayed_outputs[j][i-1] <= delayed_outputs[j][i];
		end
	end

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
		ready <= 1'b1;
	end else begin
		ready <= 1'b0;
	end
end

assign output_elem_1 = delayed_outputs[0][0];
assign output_elem_2 = delayed_outputs[1][0];
assign output_elem_3 = delayed_outputs[2][0];

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT_1 (
	.clk(clk),
	.num1(mult1_num1),
	.num2(mult1_num2),
	.product(mult1_product)
);

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT_2 (
	.clk(clk),
	.num1(mult2_num1),
	.num2(mult2_num2),
	.product(mult2_product)
);

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT_3 (
	.clk(clk),
	.num1(mult3_num1),
	.num2(mult3_num2),
	.product(mult3_product)
);

galois_add_three #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_THREE_1 (
	.num1(addthree1_num1),
	.num2(addthree1_num2),
	.num3(addthree1_num3),
	.sum(addthree1_sum)
);

galois_add_three #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_THREE_2 (
	.num1(addthree2_num1),
	.num2(addthree2_num2),
	.num3(addthree2_num3),
	.sum(addthree2_sum)
);

galois_add_three #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_THREE_3 (
	.num1(addthree3_num1),
	.num2(addthree3_num2),
	.num3(addthree3_num3),
	.sum(addthree3_sum)
);

galois_add #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_1 (
	.num1(add1_num1),
	.num2(add1_num2),
	.sum(add1_sum)
);

galois_add #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_2 (
	.num1(add2_num1),
	.num2(add2_num2),
	.sum(add2_sum)
);

galois_add #(
	.N_BITS(N_BITS),
	.PRIME_MODULUS(PRIME_MODULUS)
) ADD_3 (
	.num1(add3_num1),
	.num2(add3_num2),
	.sum(add3_sum)
);

endmodule
