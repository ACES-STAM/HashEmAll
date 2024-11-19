module top_zedboard #(
	parameter N_BITS = 254
) (
	input GCLK,
	input BTNC,
	input BTND,
	input BTNL,
	input BTNR,
	output LD0,
	output LD1
);

wire [N_BITS-1:0] out1, out2, out3;

rescueprime_permute_3x #(
    .N_BITS(N_BITS)
) RESCUE_PERMUTE (
    .clk(GCLK),
    .input_elem_1({N_BITS{BTNC}}),
    .input_elem_2({N_BITS{BTND}}),
    .input_elem_3({N_BITS{BTNL}}),
	.output_elem_1(out1),
	.output_elem_2(out2),
	.output_elem_3(out3),
    .ready(LD1)
);

// rescueprime_round_3x #(
//     .N_BITS(N_BITS),
// 	.PIPELINE_EXTRA_DELAY(1)
// ) RESCUE_ROUND (
//     .clk(GCLK),
//     .input_elem_1({N_BITS{BTNC}}),
//     .input_elem_2({N_BITS{BTND}}),
//     .input_elem_3({N_BITS{BTNL}}),
//     .round_const_1_elem_1({N_BITS{BTNC}}),
//     .round_const_1_elem_2({N_BITS{BTND}}),
//     .round_const_1_elem_3({N_BITS{BTNL}}),
//     .round_const_2_elem_1({N_BITS{BTNC}}),
//     .round_const_2_elem_2({N_BITS{BTND}}),
//     .round_const_2_elem_3({N_BITS{BTNL}}),
// 	.output_elem_1(out1),
// 	.output_elem_2(out2),
// 	.output_elem_3(out3)
// );

// rescueprime_inv_sbox #(
// 	.N_BITS(N_BITS)
// ) RESCUE_SBOX (
// 	.clk(GCLK),
// 	.base({N_BITS{BTNL}}),
// 	.result(out),
// 	.ready(LD1)
// );

// rescueprime_sbox #(
// 	.N_BITS(N_BITS)
// ) RESCUE_SBOX (
// 	.clk(GCLK),
// 	.base({N_BITS{BTNL}}),
// 	.result(out),
// 	.ready(LD1)
// );

// mult_256 MULT (
// 	.clk(GCLK),
// 	.num1({256{BTNL}}),
// 	.num2({256{BTNR}}),
// 	.product(out)
// );

// galois_mult_barrett #(
// 	.N_BITS(N_BITS)
// ) MULT (
// 	.clk(GCLK),
// 	.num1({N_BITS{BTNL}}),
// 	.num2({N_BITS{BTNR}}),
// 	.product(out)
// );

assign LD0 = (|out1) | (|out2) | (|out3);

endmodule
