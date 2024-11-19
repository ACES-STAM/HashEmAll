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


// Module that performs one permutation (all rounds) of Rescue-Prime (round_input size = 3, exponent = 5, rounds = 14).

// WARNING: Currently only works for for BN-254 field; hardcoded values.
// WARNING: Currently assumes that inverse exponent is an odd integer; hardcoded logic.

// Uses 3 galois mult instances.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 72996 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 72996 clock cycles.
//     - Accepts new request in each of the first 13 clock cycles in every 72996-clock-cycle period.

module rescueprime_permute_3x #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
	parameter RESCUE_INV_EXP = 254'h26B6A528B427B35493736AF8679AAD17535CB9D394945A0DCFE7F7A98CCCCCCD, // Size: N_BITS
	parameter RESCUE_ROUNDS = 14
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
localparam RESCUE_ROUND_LATENCY = 401*MULT_LATENCY + 1; // Clock cylces
localparam COMPUTE_PHASES = RESCUE_ROUND_LATENCY;

reg [$clog2(COMPUTE_PHASES)-1:0] compute_phase = 0;

reg [$clog2(RESCUE_ROUNDS)-1:0] round_count = 0;

reg [N_BITS-1:0] round_inputs [0:3-1];
reg [N_BITS-1:0] round_constants_1 [0:3-1];
reg [N_BITS-1:0] round_constants_2 [0:3-1];
wire [N_BITS-1:0] round_outputs [0:3-1];

// Memory region for storing Rescue-Prime round constants (1st set)
reg [N_BITS-1:0] memory_round_constants_1 [0:14*3-1];

// Memory region for storing Rescue-Prime round constants (2nd set)
reg [N_BITS-1:0] memory_round_constants_2 [0:14*3-1];

// Loading of Rescue-Prime round constants (both sets)
initial begin
	$readmemh("../data/rescue_prime_bn254_round_const_1.txt", memory_round_constants_1);
	$readmemh("../data/rescue_prime_bn254_round_const_2.txt", memory_round_constants_2);
end

// Operation logic
always @(posedge clk) begin
    compute_phase <= (compute_phase + 1'b1) % COMPUTE_PHASES;

    if (compute_phase == MULT_LATENCY) begin
        round_count <= (round_count + 1'b1) % RESCUE_ROUNDS;
        $strobe("[rescueprime_permute_3x.v] (round_count + 1)=%d", round_count);
    end

    if (0 <= compute_phase && compute_phase <= MULT_LATENCY) begin
        round_constants_1[0] <= memory_round_constants_1[3*round_count + 0];
        round_constants_1[1] <= memory_round_constants_1[3*round_count + 1];
        round_constants_1[2] <= memory_round_constants_1[3*round_count + 2];
        // $strobe("[rescueprime_permute_3x.v] round_constants_1[0]=%h", round_constants_1[0]);
        // $strobe("[rescueprime_permute_3x.v] round_constants_1[1]=%h", round_constants_1[1]);
        // $strobe("[rescueprime_permute_3x.v] round_constants_1[2]=%h", round_constants_1[2]);

		round_constants_2[0] <= memory_round_constants_2[3*round_count + 0];
        round_constants_2[1] <= memory_round_constants_2[3*round_count + 1];
        round_constants_2[2] <= memory_round_constants_2[3*round_count + 2];
        // $strobe("[rescueprime_permute_3x.v] round_constants_2[0]=%h", round_constants_2[0]);
        // $strobe("[rescueprime_permute_3x.v] round_constants_2[1]=%h", round_constants_2[1]);
        // $strobe("[rescueprime_permute_3x.v] round_constants_2[2]=%h", round_constants_2[2]);

        if (round_count == 0) begin
            round_inputs[0] <= input_elem_1;
            round_inputs[1] <= input_elem_2;
            round_inputs[2] <= input_elem_3;
        end else begin
            round_inputs[0] <= round_outputs[0];
            round_inputs[1] <= round_outputs[1];
            round_inputs[2] <= round_outputs[2];
        end
        // $strobe("[rescueprime_permute_3x.v] round_inputs[0]=%h", round_inputs[0]);
        // $strobe("[rescueprime_permute_3x.v] round_inputs[1]=%h", round_inputs[1]);
        // $strobe("[rescueprime_permute_3x.v] round_inputs[2]=%h", round_inputs[2]);
    end
end

assign output_elem_1 = round_outputs[0];
assign output_elem_2 = round_outputs[1];
assign output_elem_3 = round_outputs[2];

rescueprime_round_3x #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R),
	.RESCUE_INV_EXP(RESCUE_INV_EXP),
	.PIPELINE_EXTRA_DELAY(1)
) RESCUE_ROUND (
    .clk(clk),
    .input_elem_1(round_inputs[0]),
    .input_elem_2(round_inputs[1]),
    .input_elem_3(round_inputs[2]),
    .round_const_1_elem_1(round_constants_1[0]),
    .round_const_1_elem_2(round_constants_1[1]),
    .round_const_1_elem_3(round_constants_1[2]),
    .round_const_2_elem_1(round_constants_2[0]),
    .round_const_2_elem_2(round_constants_2[1]),
    .round_const_2_elem_3(round_constants_2[2]),
	.output_elem_1(round_outputs[0]),
	.output_elem_2(round_outputs[1]),
	.output_elem_3(round_outputs[2])
);

endmodule
