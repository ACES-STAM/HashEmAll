
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


// Module that performs Rescue-Prime's Inverse S-box operation (exponent = 5).

// WARNING: Currently only works for for BN-254 field; hardcoded values.
// WARNING: Currently assumes that inverse exponent is an odd integer; hardcoded logic.

// Uses 1 galois mult instance and takes time equivalent to 388 modular multiplications.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 5044 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 5044 clock cycles.
//     - Accepts new request in each of the first 13 clock cycles in every 5044-clock-cycle period.

module rescueprime_inv_sbox #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
	parameter RESCUE_INV_EXP = 254'h26B6A528B427B35493736AF8679AAD17535CB9D394945A0DCFE7F7A98CCCCCCD, // Size: N_BITS
    parameter PIPELINE_EXTRA_DELAY = 0 // Clock cycles
) (
    input clk,
    input  [N_BITS-1:0] base,
	output [N_BITS-1:0] result,
    output reg ready // Indicates: ready to accept new request in the current clock cycle
);

localparam MULT_LATENCY = 12+1; // Clock cylces
localparam COMPUTE_PHASES = 388*MULT_LATENCY + PIPELINE_EXTRA_DELAY;

reg [$clog2(COMPUTE_PHASES)-1:0] compute_phase = PIPELINE_EXTRA_DELAY ? (COMPUTE_PHASES - PIPELINE_EXTRA_DELAY) : 0;

reg [N_BITS-1:0] mult_num1;
reg [N_BITS-1:0] mult_num2;

reg [N_BITS-1:0] x [0:MULT_LATENCY-1];
reg [N_BITS-1:0] y [0:MULT_LATENCY-1];
reg [N_BITS-1:0] n [0:MULT_LATENCY-1];
reg [N_BITS-1:0] n_new [0:MULT_LATENCY-1];

wire [N_BITS-1:0] mult_product;

integer i;

// Operation logic
always @(posedge clk) begin
    compute_phase <= (compute_phase + 1'b1) % COMPUTE_PHASES;

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
        x[0] <= base;
        y[0] <= base;
        n[0] <= RESCUE_INV_EXP - 'b1;
        n_new[0] <= (RESCUE_INV_EXP - 'b1) >> 1;
		for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			x[i] <= x[i-1];
			y[i] <= y[i-1];
			n[i] <= n[i-1];
			n_new[i] <= n_new[i-1];
		end

		mult_num1 <= base;
		mult_num2 <= base;
	end else if (MULT_LATENCY <= compute_phase && compute_phase <= 390*MULT_LATENCY - 1) begin
		n[0] <= n_new[MULT_LATENCY-1];

		if (n[MULT_LATENCY-1] & 'b1) begin
			n_new[0] <= n_new[MULT_LATENCY-1] >> 1;

			x[0] <= x[MULT_LATENCY-1];
			y[0] <= mult_product; // mult_product = y_new = y_old * x_old

			mult_num1 <= x[MULT_LATENCY-1];
			mult_num2 <= x[MULT_LATENCY-1];
		end else begin
			x[0] <= mult_product; // mult_product = x_new = x_old * x_old
			y[0] <= y[MULT_LATENCY-1];

			if (n_new[MULT_LATENCY-1] & 'b1) begin
				n_new[0] <= n_new[MULT_LATENCY-1] - 'b1;

				mult_num1 <= mult_product; // mult_product = x_new = x_old * x_old
				mult_num2 <= y[MULT_LATENCY-1];
			end else begin
				n_new[0] <= n_new[MULT_LATENCY-1] >> 1;

				mult_num1 <= mult_product; // mult_product = x_new = x_old * x_old
				mult_num2 <= mult_product; // mult_product = x_new = x_old * x_old
			end
		end

		for (i = 1; i < MULT_LATENCY; i = i + 1) begin
			x[i] <= x[i-1];
			y[i] <= y[i-1];
			n[i] <= n[i-1];
			n_new[i] <= n_new[i-1];
		end
	end

	if (0 <= compute_phase && compute_phase <= MULT_LATENCY - 1) begin
		ready <= 1'b1;
	end else begin
		ready <= 1'b0;
	end
end

assign result = mult_product; // mult_product = base**RESCUE_INV_EXP

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

endmodule
