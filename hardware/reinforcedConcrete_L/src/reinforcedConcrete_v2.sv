module reinforcedConcrete_v2 #(
    parameter STATE_SIZE = 3,
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925 // Size: N_BITS + 1
) (
    input [N_BITS-1:0] inState1[STATE_SIZE][13],
    input [N_BITS-1:0] inState2[STATE_SIZE][13],
    input clk, reset, enable,
    output [N_BITS-1:0] outState1[STATE_SIZE][13],
    output [N_BITS-1:0] outState2[STATE_SIZE][13],
    output done
);
    logic done1, done2;
    assign done = done1 & done2;

    rcPermutation permutation_inst1(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .inState(inState1),
        .outState(outState1),
        .done(done1)
    );
    rcPermutation permutation_inst2(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .inState(inState2),
        .outState(outState2),
        .done(done2)
    );
endmodule