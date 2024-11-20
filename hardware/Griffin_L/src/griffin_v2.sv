module griffin_v2 #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
    input clk, reset, enable,
    input [N_BITS-1:0] inState1[STATE_SIZE][13],
    input [N_BITS-1:0] inState2[STATE_SIZE][13],
    input [N_BITS-1:0] inState3[STATE_SIZE][13],
    output logic [N_BITS-1:0] outState1[STATE_SIZE][13],
    output logic [N_BITS-1:0] outState2[STATE_SIZE][13],
    output logic [N_BITS-1:0] outState3[STATE_SIZE][13],
    output done
);
    logic done1, done2, done3;
    assign done = done1;
    griffin griffin_1(
        .clk(clk),
      .reset(reset),
        .inState(inState1),
        .enable(enable),
        .done(done1),
        .outState(outState1)
    );

    griffin griffin_2(
        .clk(clk),
      .reset(reset),
        .inState(inState2),
        .enable(enable),
        .done(done2),
        .outState(outState2)
    );

    griffin griffin_3(
      .reset(reset),
        .clk(clk),
        .inState(inState3),
        .enable(enable),
        .done(done3),
        .outState(outState3)
    );
endmodule