module nonlinear #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
  	parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3
) (
    input [N_BITS-1:0] inState[STATE_SIZE],
    input clk, reset, enable,
    output logic [N_BITS-1:0] outState[STATE_SIZE],
    output logic done
);
    localparam BARRETT_LATENCY = 12;
    localparam DINV = 254'h26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd;
    localparam ALPHA =254'h16a2d6af5595e96b6af9a3585a58267e36ed309299558a78ca02d23b86038f00;
    localparam BETA = 254'h2dbfb5efc8271e3c08c1f953619e5a578cbb6f891a5c18ce00b33bed129d7426;
    localparam N_PRECOMPUTE = STATE_SIZE-2;
  enum logic[2:0] {INIT, COMPUTE_Y0, SAVE_POWER ,COMPUTE_OTHERS, DONE} state, next_state;
    logic [N_BITS-1:0] mult1_num1, mult1_num2, mult2_num1, mult2_num2, mult1_result, mult2_result;
    logic [N_BITS-1:0] mult_reg, pow_5_reg;
    logic [N_BITS-1:0] precompute_reg;
    logic [N_BITS-1:0] dinv;
    logic compute_y0_done, compute_others_done, compute_y0_start;
    logic pow_5_start, pow_5_done;
    logic[3:0] ct_barrett, ct_power, ct_precompute;
    logic  mult_flag, mult_result_ready, pow_result_ready,precomputation_result_ready;
    logic [N_BITS-1:0] y0, y1, x_i,l_i, kL;
    logic [4:0] i;
    logic [1:0] ct_step;
    logic [N_BITS-1:0] add_num1, add_num2, add_num3, add_sum;
    assign mult_flag = dinv & 1'b1;
    assign compute_y0_done = (|dinv)? 0:1;
    always_ff @( posedge clk ) begin
      //$display("current state is %d, next state is %d", state, next_state);
        if (reset) state <= INIT;
        else state <= next_state;
    end
    always_comb begin
        case (state)
            INIT: next_state = enable? COMPUTE_Y0:INIT; 
            COMPUTE_Y0: next_state = compute_y0_done? SAVE_POWER:COMPUTE_Y0;
          SAVE_POWER: next_state =(ct_barrett == 13)? COMPUTE_OTHERS: SAVE_POWER;
            COMPUTE_OTHERS: next_state = compute_others_done? DONE: COMPUTE_OTHERS;
            DONE: next_state = INIT; 
            default: next_state = INIT;
        endcase
    end

    always_ff @( posedge clk ) begin
        case (state)
            INIT: begin
                dinv <= DINV;
                ct_barrett <= 0;
                compute_y0_start <= 1;
                pow_5_start <= 1;
                done <= 0;
                mult_result_ready <= 0;
                pow_5_done <= 0;
                precomputation_result_ready <= 0;
                ct_precompute <= 0;
                ct_step <= 0;
              	compute_others_done <= 0;
                ct_power <= 0;
            end 
            COMPUTE_Y0: begin
              //$display("dinv is %h", dinv);
                if (ct_barrett == 12) begin
                    dinv <= dinv >> 1;
                    ct_barrett <= 0;
                end
                else if (ct_barrett == 0 && !compute_y0_done) begin
                    ct_barrett <= ct_barrett + 1;
                    if (mult_flag) begin
                        mult_result_ready <= 1;
                        pow_result_ready <= 0;
                      	precomputation_result_ready <= 0; 
                        if (compute_y0_start) begin
                          	compute_y0_start <= 0;
                            mult1_num1 <= 1;
                          //$display("x0 is %h", inState[0]);
                          mult1_num2 <= inState[0];
                            mult2_num1 <= inState[0];
                          mult2_num2 <= inState[0];
                        end
                        else begin
                            mult1_num1 <= mult_reg;
                            mult1_num2 <= mult2_result;
                            mult2_num1 <= mult2_result;
                            mult2_num2 <= mult2_result;
                        end
                    end
                    else begin
                        mult_result_ready <= 0;
                        if (ct_power < 4) begin
                            ct_power <= ct_power + 1;
                            pow_result_ready <= 1;
                          	precomputation_result_ready <= 0;
                            if (pow_5_start) begin
                              	pow_5_start <= 0;
                                mult1_num1 <= inState[1];
                                mult1_num2 <= inState[1];
                            end
                            else begin
                                mult1_num1 <= inState[1];
                                mult1_num2 <= pow_5_reg;
                            end
                        end
                        else begin
                            pow_result_ready <= 0;
                            if (ct_precompute < N_PRECOMPUTE) begin
                                precomputation_result_ready <= 1;
                                ct_precompute <= ct_precompute+1;
                                mult1_num1 <= ALPHA;
                              	mult1_num2 <= inState[2];
                            end
                        end
                        mult2_num1 <= mult2_result;
                        mult2_num2 <= mult2_result;
                    end
                end
                else begin
                    if (!compute_y0_done) ct_barrett <= ct_barrett + 1;
                end
            end

            SAVE_POWER: begin
              if (ct_barrett < 13) begin
                    if (ct_barrett == 0) begin
                        outState[0] <= mult_reg;
                        outState[1] <= pow_5_reg;
                        i <= 1;
                        y0 <= mult_reg;
                        y1 <= pow_5_reg;
                        x_i <= 0;
                    end
                    ct_barrett <= ct_barrett + 1;
                end
                else ct_barrett <= 0;

            end

            COMPUTE_OTHERS: begin
              //$display("ct_step = %d", ct_step);
              //$display("ct_barrett = %d",ct_barrett);
                case (ct_step)
                    0: begin
                      	ct_barrett <= ct_barrett + 1;
                        if (ct_barrett == 0) begin
                            mult1_num1 <= l_i;
                            mult1_num2 <= l_i;
                            mult2_num1 <= precompute_reg;
                            mult2_num2 <= l_i;
                        end
                        else if (ct_barrett == 12) begin
                            ct_step <= ct_step + 1;
                            ct_barrett <= 0;
                        end

                    end 
                    1: begin
						ct_barrett <= ct_barrett + 1;
                        if (ct_barrett == 0) begin
                            kL <= mult2_result;
                            mult1_num1 <= mult1_result;
                            mult1_num2 <= inState[2];
                            mult2_num1 <= inState[2];
                            mult2_num2 <= BETA;
                        end

                        else if (ct_barrett == 12) begin
                            ct_step <= ct_step + 1;
                            ct_barrett <= 0;
                        end
                    end
                    2: begin
                        add_num1 <= mult1_result;
                        add_num2 <= kL;
                        add_num3 <= mult2_result;
                      	compute_others_done <= 1;
                    end
                endcase
            end

            DONE: begin
                done <= 1;
                outState[2] <= add_sum;
            end
        endcase
    end

    always_latch begin
        if (pow_result_ready) pow_5_reg <= mult1_result;
        if (mult_result_ready) mult_reg <= mult1_result;
        if (precomputation_result_ready) precompute_reg <= mult1_result;
    end
    galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult_instance(
        .clk(clk),
        .num1(mult1_num1),
        .num2(mult1_num2),
        .product(mult1_result)
    );

    galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) square_instance(
        .clk(clk),
        .num1(mult2_num1),
        .num2(mult2_num2),
        .product(mult2_result)
    );
    Li #(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) li_instance(
        .clk(clk),
        .y0(y0),
        .y1(y1),
        .i(i),
        .x_i(x_i),
        .l_i(l_i)
    );
  	galois_add_three#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) add_three_instance (
        .num1(add_num1),
        .num2(add_num2),
        .num3(add_num3),
        .sum(add_sum)
    );
endmodule