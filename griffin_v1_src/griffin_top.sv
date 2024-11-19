module griffin_top #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
    input [N_BITS-1:0] inState,
    input rd, wr,
    input clk, enable, reset,
    output logic [N_BITS-1:0] outState,
    output logic done
);
    logic [5:0] wr_ptr, rd_ptr;
    logic [N_BITS-1:0] griffin_in[13], griffin_out[13];
    logic [N_BITS-1:0] fifo_in[STATE_SIZE*13], fifo_out[STATE_SIZE*13];
    always_ff @( posedge clk ) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end
        else begin
            if (wr) begin
                fifo_in[wr_ptr] <= inState;
                wr_ptr <= wr_ptr + 1;
            end
            else if (rd) begin
                rd_ptr <= rd_ptr + 1;
                outState <= fifo_out[rd_ptr];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < 13; i++) begin
            for (int j = 0; j < STATE_SIZE; j++) begin
                griffin_in[j][i] = fifo_in[i*3+j];
                fifo_out[i*3+j] = griffin_out[j][i];
            end
        end
    end
    griffin griffin_instance(
        .reset(reset),
        .enable(enable),
        .inState(griffin_in),
        .outState(griffin_out),
        .done(done)
    );
endmodule