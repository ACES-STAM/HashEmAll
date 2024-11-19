module concrete #(
    parameter  N_BITS=254 ,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001,
    parameter STATE_SIZE = 3
) (
    input clk,
    input [N_BITS-1:0] inState[STATE_SIZE],
  	input [N_BITS-1:0] round_constants[STATE_SIZE],
    output [N_BITS-1:0] outState[STATE_SIZE]
);
    logic [N_BITS-1:0] sum, sum_reg;
  logic [N_BITS-1:0] inState_reg[STATE_SIZE];
    galois_add_three #(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) adder_three_instance_0(
        .num1(inState[0]),
        .num2(inState[1]),
        .num3(inState[2]),
        .sum(sum)
    );

    always_ff @( posedge clk ) begin : blockName
        sum_reg <= sum;
      for(int i = 0; i < STATE_SIZE; i++)begin
        inState_reg[i] <= inState[i];
      end
    end
    generate
        genvar i;
        for ( i = 0; i < STATE_SIZE; i++) begin
            galois_add_three #(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) add_three_instance_1(
              .num1(inState_reg[i]),
                .num2(round_constants[i]),
                .num3(sum_reg),
                .sum(outState[i])
            );
        end
    endgenerate
endmodule