module griffin_top #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
    input [N_BITS-1:0] inState,
    input clk, reset, enable, wr, rd,
    output logic [N_BITS-1:0] outState,
    output logic done, rd_done
);
    logic [N_BITS-1:0] griffin_in[STATE_SIZE], griffin_out[STATE_SIZE];
    logic [$clog2(STATE_SIZE):0] wr_ptr, rd_ptr;
  assign rd_done = (rd_ptr == STATE_SIZE)? 1:0;
    always_ff @( posedge clk ) begin : blockName
        if (reset) begin
            wr_ptr <= 0;
          	rd_ptr <= 0;
        end
        else begin
            if (wr) begin
                griffin_in[wr_ptr] <= inState;
                wr_ptr <= wr_ptr + 1;
            end
          else if (rd && !rd_done ) begin
                outState <= griffin_out[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    griffin#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R), .STATE_SIZE(STATE_SIZE), .NUM_ROUNDS(NUM_ROUNDS)) griffin_instance(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .inState(griffin_in),
        .outState(griffin_out),
        .done(done)
    );
endmodule