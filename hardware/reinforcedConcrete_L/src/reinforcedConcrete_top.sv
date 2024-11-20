module reinforcedConcrete_top #(
    parameter STATE_SIZE = 3,
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925 // Size: N_BITS + 1
) (
    input [N_BITS-1:0] inState,
    input [1:0] wr, rd,
    input clk, reset, enable,
    output logic [N_BITS-1:0] outState,
    output logic done
);

    logic [5:0] wr_ptr1, rd_ptr1;
    logic [5:0] wr_ptr2, rd_ptr2;
    logic [N_BITS-1:0] perm_in1[STATE_SIZE][13], perm_out1[STATE_SIZE][13];
    logic [N_BITS-1:0] fifo_in1[STATE_SIZE*13], fifo_out1[STATE_SIZE*13];
        logic [N_BITS-1:0] perm_in2[STATE_SIZE][13], perm_out2[STATE_SIZE][13];
    logic [N_BITS-1:0] fifo_in2[STATE_SIZE*13], fifo_out2[STATE_SIZE*13];


    always_ff @( posedge clk ) begin
        if (reset) begin
            wr_ptr1 <= 0;
            wr_ptr2 <= 0;
   
            rd_ptr1 <= 0;
            rd_ptr2 <= 0;

        end
        else begin
            if (wr[0] && wr_ptr1 < 39) begin
                fifo_in1[wr_ptr1] <= inState;
                wr_ptr1 <= wr_ptr1 + 1;
            end
            else if (wr[1] && wr_ptr2 < 39) begin
                fifo_in2[wr_ptr2] <= inState;
                wr_ptr2 <= wr_ptr2 + 1;
            end
 
            else if (rd[0] && rd_ptr1 < 39) begin
                rd_ptr1 <= rd_ptr1 + 1;
                outState <= fifo_out1[rd_ptr1];
            end
            else if (rd[1] && rd_ptr2 < 39) begin
                rd_ptr2 <= rd_ptr2 + 1;
                outState <= fifo_out2[rd_ptr2];
            end

        end
    end

    always_comb begin
        for (int i = 0; i < 13; i++) begin
            for (int j = 0; j < STATE_SIZE; j++) begin
                perm_in1[j][i] = fifo_in1[i*3+j];
                fifo_out1[i*3+j] = perm_out1[j][i];
                perm_in2[j][i] = fifo_in2[i*3+j];
                fifo_out2[i*3+j] = perm_out2[j][i];
            end
        end
    end

    reinforcedConcrete_v2 rc_inst (
        .inState1(perm_in1),
        .inState2(perm_in2),
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .outState1(perm_out1),
        .outState2(perm_out2),
        .done(done)
    );
endmodule