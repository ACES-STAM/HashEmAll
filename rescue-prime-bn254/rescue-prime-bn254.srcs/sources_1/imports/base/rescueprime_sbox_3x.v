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


// Module that performs Rescue-Prime's S-box operation (exponent = 5).
// It parallely processes three independent inputs and produces three corresponding outputs.

// Uses 1 galois mult instance per input and takes time equivalent to 3 modular multiplications.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 39 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 39 clock cycles.
//     - Accepts new request in each of the first 13 clock cycles in every 39-clock-cycle period.

module rescueprime_sbox_3x #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter PIPELINE_EXTRA_DELAY = 0 // Clock cycles
) (
    input clk,
    input  [N_BITS-1:0] base1,
    input  [N_BITS-1:0] base2,
    input  [N_BITS-1:0] base3,
	output [N_BITS-1:0] result1,
	output [N_BITS-1:0] result2,
	output [N_BITS-1:0] result3,
    output reg ready // Indicates: ready to accept new request in the current clock cycle
);

localparam MULT_LATENCY = 12+1; // Clock cylces
localparam COMPUTE_PHASES = 3*MULT_LATENCY + PIPELINE_EXTRA_DELAY;

reg [$clog2(COMPUTE_PHASES)-1:0] compute_phase = PIPELINE_EXTRA_DELAY ? (COMPUTE_PHASES - PIPELINE_EXTRA_DELAY) : 0;

reg [N_BITS-1:0] mult1_num1;
reg [N_BITS-1:0] mult1_num2;
reg [N_BITS-1:0] mult2_num1;
reg [N_BITS-1:0] mult2_num2;
reg [N_BITS-1:0] mult3_num1;
reg [N_BITS-1:0] mult3_num2;

reg [N_BITS-1:0] base1_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base1_pow_2_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base1_pow_3_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base2_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base2_pow_2_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base2_pow_3_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base3_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base3_pow_2_saved [0:MULT_LATENCY-1];
reg [N_BITS-1:0] base3_pow_3_saved [0:MULT_LATENCY-1];

wire [N_BITS-1:0] mult1_product;
wire [N_BITS-1:0] mult2_product;
wire [N_BITS-1:0] mult3_product;

integer i;

// Operation logic
always @(posedge clk) begin
    compute_phase <= (compute_phase + 1'b1) % COMPUTE_PHASES;

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
        base1_saved[0] <= base1;
        base2_saved[0] <= base2;
        base3_saved[0] <= base3;
		for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			base1_saved[i] <= base1_saved[i-1];
			base2_saved[i] <= base2_saved[i-1];
			base3_saved[i] <= base3_saved[i-1];
		end

		mult1_num1 <= base1;
		mult1_num2 <= base1;
		mult2_num1 <= base2;
		mult2_num2 <= base2;
		mult3_num1 <= base3;
		mult3_num2 <= base3;
	end else if (MULT_LATENCY <= compute_phase && compute_phase <= 2*MULT_LATENCY - 1) begin
        for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			base1_saved[i] <= base1_saved[i-1];
			base2_saved[i] <= base2_saved[i-1];
			base3_saved[i] <= base3_saved[i-1];
		end

		base1_pow_2_saved[0] <= mult1_product; // mult1_product = base1 ** 2
		base2_pow_2_saved[0] <= mult2_product; // mult2_product = base2 ** 2
		base3_pow_2_saved[0] <= mult3_product; // mult3_product = base3 ** 2
		for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			base1_pow_2_saved[i] <= base1_pow_2_saved[i-1];
			base2_pow_2_saved[i] <= base2_pow_2_saved[i-1];
			base3_pow_2_saved[i] <= base3_pow_2_saved[i-1];
		end

		mult1_num1 <= mult1_product; // mult1_product = base1 ** 2
		mult1_num2 <= base1_saved[MULT_LATENCY-1];
		mult2_num1 <= mult2_product; // mult2_product = base2 ** 2
		mult2_num2 <= base2_saved[MULT_LATENCY-1];
		mult3_num1 <= mult3_product; // mult3_product = base3 ** 2
		mult3_num2 <= base3_saved[MULT_LATENCY-1];
	end else if (2*MULT_LATENCY <= compute_phase && compute_phase <= 3*MULT_LATENCY - 1) begin
        for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			base1_pow_2_saved[i] <= base1_pow_2_saved[i-1];
			base2_pow_2_saved[i] <= base2_pow_2_saved[i-1];
			base3_pow_2_saved[i] <= base3_pow_2_saved[i-1];
		end

        base1_pow_3_saved[0] <= mult1_product; // mult1_product = base1 ** 3
        base2_pow_3_saved[0] <= mult2_product; // mult2_product = base2 ** 3
        base3_pow_3_saved[0] <= mult3_product; // mult3_product = base3 ** 3
        for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			base1_pow_3_saved[i] <= base1_pow_3_saved[i-1];
			base2_pow_3_saved[i] <= base2_pow_3_saved[i-1];
			base3_pow_3_saved[i] <= base3_pow_3_saved[i-1];
		end

		mult1_num1 <= mult1_product; // mult1_product = base1 ** 3
		mult1_num2 <= base1_pow_2_saved[MULT_LATENCY-1];
		mult2_num1 <= mult2_product; // mult2_product = base2 ** 3
		mult2_num2 <= base2_pow_2_saved[MULT_LATENCY-1];
		mult3_num1 <= mult3_product; // mult3_product = base3 ** 3
		mult3_num2 <= base3_pow_2_saved[MULT_LATENCY-1];
	end

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
		ready <= 1'b1;
	end else begin
		ready <= 1'b0;
	end
end

assign result1 = mult1_product; // mult1_product = base1 ** 5
assign result2 = mult2_product; // mult2_product = base2 ** 5
assign result3 = mult3_product; // mult3_product = base3 ** 5

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT1 (
	.clk(clk),
	.num1(mult1_num1),
	.num2(mult1_num2),
	.product(mult1_product)
);

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT2 (
	.clk(clk),
	.num1(mult2_num1),
	.num2(mult2_num2),
	.product(mult2_product)
);

galois_mult_barrett #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
) MULT3 (
	.clk(clk),
	.num1(mult3_num1),
	.num2(mult3_num2),
	.product(mult3_product)
);

endmodule
