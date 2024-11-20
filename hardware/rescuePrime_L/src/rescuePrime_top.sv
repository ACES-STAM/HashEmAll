module rescuePrime_top #(
     parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
    input [N_BITS-1:0] inState,
    input clk, enable, reset, wr, rd,
    output logic [N_BITS-1:0] outState,
    output logic done
);
    logic [5:0] rd_ptr, wr_ptr;
    logic [N_BITS-1:0] perm_in[STATE_SIZE][13], perm_out[STATE_SIZE][13];
    logic [N_BITS-1:0] vectorIn[STATE_SIZE*13], vectorOut[STATE_SIZE*13];
    always_ff @( posedge clk ) begin : blockName
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end
        else begin
            if (wr && wr_ptr < 39) begin
                vectorIn[wr_ptr] <= inState;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd && rd_ptr < 39) begin
                outState <= vectorOut[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    always_comb begin
        for(int i = 0; i < 13; i++) begin
            for (int j = 0; j < STATE_SIZE; j++) begin
                perm_in[j][i] = vectorIn[i*3+j];
                vectorOut[i*3+j] = perm_out[j][i];
            end
        end
    end

    rescuePrime rescuePrimePermutationInstance(
        .inState(perm_in),
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .outState(perm_out),
        .done(done)
    );
endmodule