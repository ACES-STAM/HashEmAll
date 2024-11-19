module galois_add_three #(
	parameter N_BITS = 254,
	parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001 // Size: N_BITS
) (
	input  [N_BITS-1:0] num1,
	input  [N_BITS-1:0] num2,
	input  [N_BITS-1:0] num3,
	output [N_BITS-1:0] sum
);

logic [(N_BITS+2)-1:0] temp;
logic signed [(N_BITS+2)-1:0] temp1;
logic signed [(N_BITS+2)-1:0] temp2;

assign temp = num1 + num2 + num3;
assign temp1 = temp - PRIME_MODULUS;
assign temp2 = temp - 2*PRIME_MODULUS;
assign sum = temp2 >= 0 ? temp2[N_BITS-1:0] : temp1 >= 0 ? temp1[N_BITS-1:0] : temp[N_BITS-1:0];

endmodule