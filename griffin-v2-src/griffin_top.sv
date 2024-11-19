module griffin_top #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
    input [N_BITS-1:0] inState,
    input [2:0] rd, 
    input [2:0] wr,
    input clk, enable, reset,
    output logic [N_BITS-1:0] outState,
    output logic done
);  
    logic [5:0] wr_ptr_1, rd_ptr_1, wr_ptr_2, rd_ptr_2, wr_ptr_3, rd_ptr_3;
    logic [N_BITS-1:0] griffin_in1[STATE_SIZE][13],griffin_in2[STATE_SIZE][13],griffin_in3[STATE_SIZE][13];
    logic [N_BITS-1:0] griffin_out1[STATE_SIZE][13],griffin_out2[STATE_SIZE][13],griffin_out3[STATE_SIZE][13];
    logic [N_BITS-1:0] fifo_in1[STATE_SIZE*13], fifo_in2[STATE_SIZE*13], fifo_in3[STATE_SIZE*13];
    logic [N_BITS-1:0] fifo_out1[STATE_SIZE*13], fifo_out2[STATE_SIZE*13], fifo_out3[STATE_SIZE*13];
    always_ff @( posedge clk ) begin : blockName
        if(reset) begin
            wr_ptr_1 <= 0;
            wr_ptr_2 <= 0;
            wr_ptr_3 <= 0;
            rd_ptr_1 <= 0;
            rd_ptr_2 <= 0;
            rd_ptr_3 <= 0;
        end
        else begin
            if (wr[0] & wr_ptr_1 < 39) begin
                wr_ptr_1 <= wr_ptr_1 + 1;
                fifo_in1[wr_ptr_1] <= inState;
            end
            else if (wr[1] && wr_ptr_2 < 39) begin
                wr_ptr_2 <= wr_ptr_2 + 1;
                fifo_in2[wr_ptr_2] <= inState;
            end
            else if (wr[2] & wr_ptr_3 < 39) begin
                wr_ptr_3 <= wr_ptr_3 + 1;
                fifo_in3[wr_ptr_3] <= inState;
            end
            else if (rd[0] && rd_ptr_1 < 39) begin
                rd_ptr_1 <= rd_ptr_1 + 1;
                outState <= fifo_out1[rd_ptr_1];
            end
            else if (rd[1] && rd_ptr_2 < 39) begin
                rd_ptr_2 <= rd_ptr_2 + 1;
                outState <= fifo_out2[rd_ptr_2];
            end
            else if (rd[2] && rd_ptr_3 < 39) begin
                rd_ptr_3 <= rd_ptr_3 + 1;
                outState <= fifo_out3[rd_ptr_3];
            end
        end
    end


    griffin_v2 griffin_v2_inst(
        .clk(clk),
        .reset(reset), 
        .enable(enable),
        .inState1(griffin_in1),
        .inState2(griffin_in2),
        .inState3(griffin_in3),
        .outState1(griffin_out1),
        .outState2(griffin_out2),
        .outState3(griffin_out3),
        .done(done)
    );

    always_comb begin
        for(int i = 0; i < 13; i++) begin
            for(int j = 0; j < STATE_SIZE; j++) begin
                griffin_in1[j][i] = fifo_in1[i*j+3];
                griffin_in2[j][i] = fifo_in2[i*j+3];
                griffin_in3[j][i] = fifo_in3[i*j+3];
                fifo_out1[i*j+3] = griffin_out1[j][i];
                fifo_out2[i*j+3] = griffin_out2[j][i];
                fifo_out3[i*j+3] = griffin_out3[j][i];
            end
        end
    end
endmodule