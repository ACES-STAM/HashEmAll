module Li #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
) (
    input [4:0] i,
    input [N_BITS-1:0] y0,
    input [N_BITS-1:0] y1,
    input [N_BITS-1:0] x_i,
    output [N_BITS-1:0] l_i,
    input clk
); 
    logic [N_BITS-1:0] y0_i;
    galois_mult_254#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) mult_instance (
        .clk(clk),
        .num1(i),
        .num2(y0),
        .result(y0_i)
    );
    galois_add_three#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) galois_add_instance (
        .num1(y0_i),
        .num2(y1),
        .num3(x_i),
        .sum(l_i)
    );
endmodule