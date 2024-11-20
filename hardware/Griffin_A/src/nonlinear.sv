module nonlinear #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
  	parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3
) (
  	input [N_BITS-1:0] inState[STATE_SIZE][13],
    input clk, reset, enable,
  	output logic [N_BITS-1:0] outState[STATE_SIZE][13],
    output logic done
    //output logic y0_rd, y2_rd
);
    localparam BARRETT_LATENCY = 12;
    localparam DINV = 254'h26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd;
    localparam ALPHA =254'h16a2d6af5595e96b6af9a3585a58267e36ed309299558a78ca02d23b86038f00;
    localparam BETA = 254'h2dbfb5efc8271e3c08c1f953619e5a578cbb6f891a5c18ce00b33bed129d7426;
    localparam N_PRECOMPUTE = STATE_SIZE-2;
//  enum logic[2:0] {INIT, COMPUTE_Y0, SAVE_POWER ,COMPUTE_OTHERS, DONE} state, next_state;
localparam INIT           = 3'd0;
localparam  COMPUTE_Y0     = 3'd1;
localparam SAVE_POWER     = 3'd2;
localparam COMPUTE_OTHERS = 3'd3;
localparam DONE           = 3'd4;
    logic [2:0] state, next_state;
 
    logic [N_BITS-1:0] mult1_num1, mult1_num2, mult2_num1, mult2_num2, mult1_result, mult2_result;
    logic [N_BITS-1:0] mult_reg[BARRETT_LATENCY+1], pow_5_reg[BARRETT_LATENCY+1];
    logic [N_BITS-1:0] x1_reg[13], x2_reg[13], kL[13];
    logic [N_BITS-1:0] precompute_reg[BARRETT_LATENCY+1];
    logic [N_BITS-1:0] dinv;
    logic compute_y0_done, compute_others_done, compute_y0_start;
    logic pow_5_start, pow_5_done;
    logic[3:0] ct_barrett, ct_power, ct_precompute;
    logic  mult_flag, mult_result_ready,pow_result_ready,precomputation_result_ready;
    logic mult_result_ready_reg[BARRETT_LATENCY+1], pow_result_ready_reg[BARRETT_LATENCY+1], precomputation_result_ready_reg[BARRETT_LATENCY+1];
  logic [N_BITS:0] sum_mults;
  logic[N_BITS-1:0] sum_reduced;
    logic ct_step;
    logic [N_BITS-1:0] add_num1, add_num2, add_num3, add_sum;
  assign sum_mults = (ct_barrett > 0)? mult_reg[ct_barrett-1] + pow_5_reg[ct_barrett - 1]:0; 
  assign sum_reduced = (sum_mults > PRIME_MODULUS)?sum_mults-PRIME_MODULUS: sum_mults[N_BITS-1:0];
    assign mult_flag = dinv & 1'b1;
    assign compute_y0_done = (|dinv)? 0:1;
    always_ff @( posedge clk ) begin
      //$display("current state is %d, next state is %d", state, next_state);
        if (reset) state <= INIT;
        else state <= next_state;
    end
always_comb begin
    case (state)
        INIT: next_state = enable ? COMPUTE_Y0 : INIT;
        COMPUTE_Y0: next_state = compute_y0_done ? SAVE_POWER : COMPUTE_Y0;
      	SAVE_POWER: next_state = (ct_barrett == 13) ? COMPUTE_OTHERS : SAVE_POWER;
        COMPUTE_OTHERS: next_state = compute_others_done ? DONE : COMPUTE_OTHERS;
        DONE: next_state = INIT;
        default: next_state = INIT;
    endcase
end


    always_ff @( posedge clk ) begin
        case (state)
            INIT: begin
              //	y2_rd <= 0;
              //  y0_rd <= 0;
                dinv <= DINV;
                ct_barrett <= 0;
                compute_y0_start <= 1;
                pow_5_start <= 1;
                done <= 0;
                mult_result_ready_reg[0] <= 0;
                pow_5_done <= 0;
                precomputation_result_ready_reg[0] <= 0;
                pow_result_ready_reg[0] <= 0;
                ct_precompute <= 0;
                ct_step <= 0;
              	compute_others_done <= 0;
                ct_power <= 0;
            end 
            COMPUTE_Y0: begin
              ct_barrett <= ct_barrett + 1;
              //$display("mult_reg is %h", mult_reg[0]);
                if(!compute_y0_done) begin
                    if (mult_flag) begin
                        mult_result_ready_reg[0] <= 1;
                        pow_result_ready_reg[0] <= 0;
                        precomputation_result_ready_reg[0] <= 0;
                        if (compute_y0_start) begin
                         	
                            
//                           $display("ct_barrett is %d", ct_barrett);
//                           $display("input[0][%1d] is %h", ct_barrett, inState[0][ct_barrett]);
//                           $display("input[1][%1d] is %h", ct_barrett, inState[1][ct_barrett]);
//                           $display("input[2][%1d] is %h", ct_barrett, inState[2][ct_barrett]);
                          mult1_num1 <= 1;
                            mult1_num2 <= inState[0][ct_barrett];
                            mult2_num1 <= inState[0][ct_barrett];
                            mult2_num2 <= inState[0][ct_barrett];
                            x1_reg[ct_barrett] <= inState[1][ct_barrett];
                            x2_reg[ct_barrett] <= inState[2][ct_barrett];
                                  
                        end
                      
                        else begin
                            mult1_num1 <= mult_reg[ct_barrett];
                            mult1_num2 <= mult2_result;
                            mult2_num1 <= mult2_result;
                            mult2_num2 <= mult2_result;
                        end
                    end
                    else begin
                        mult_result_ready_reg[0] <= 0;
                      	if (ct_power < 4) begin
                          //$display("ct_power is %d", ct_power);
                            pow_result_ready_reg[0] <= 1;
                            precomputation_result_ready_reg[0] <= 0;
                            if (pow_5_start) begin
                            // $display("ct_barrett = %d, mult_num1 and 2 is %h", ct_barrett, x1_reg[ct_barrett]);
                                mult1_num1 <= x1_reg[ct_barrett];
                                mult1_num2 <= x1_reg[ct_barrett];
                            end
                            else begin
                            // $display("ct_barrett = %d, mult_num1 and 2 is %h", ct_barrett, x1_reg[ct_barrett]);
                              //$display("ct_barrett = %d, mult_num2 is %h", ct_barrett, pow_5_reg[ct_barrett]);
                                mult1_num1 <= x1_reg[ct_barrett];
                                mult1_num2 <= pow_5_reg[ct_barrett];
                            end
                        end
                        else begin
                            pow_result_ready_reg[0] <= 0;
                            
                            if (ct_precompute < N_PRECOMPUTE) begin
                                precomputation_result_ready_reg[0] <= 1;
                                mult1_num1 <= ALPHA;
                                mult1_num2 <= x2_reg[ct_barrett];
                              //$display("ct_barrett = %d, x2_reg is %h", ct_barrett, x2_reg[ct_barrett]);
        
                            end
                        end
                        mult2_num1 <= mult2_result;
                        mult2_num2 <= mult2_result;
                    end

                    if (ct_barrett == 12) begin
                        dinv <= dinv >> 1;
                        ct_barrett <= 0;
                        if (compute_y0_start) compute_y0_start <= 0;
                      	else if (ct_power < 4 && !mult_flag) begin 
                            //mult_result_ready_reg[0] <= 0;
                            ct_power <= ct_power + 1;
                            if (pow_5_start) pow_5_start <= 0;
                        end
                        
                      else if (ct_precompute < N_PRECOMPUTE && !mult_flag) begin
                            //mult_result_ready_reg[0] <= 0;
                            ct_precompute <= ct_precompute + 1;
                        end 
                    end
                end

            end

            SAVE_POWER: begin // output outState[0], outState[1]
              if (ct_barrett < 14) begin
              //  if (y0_rd) begin
                	//$display("outState[0] = %h", outState[0]);
                	//$display("outState[1] = %h", outState[1]);
                	//end
                	  //y0_rd <= 1;
                    //$display("ct_barrett = %d", ct_barrett);
//                     $display("outState[0][%1d] = %h", ct_barrett-1, mult_reg[ct_barrett-1]);
//                     $display("outState[1][%1d] = %h", ct_barrett-1, pow_5_reg[ct_barrett-1]);
                outState[0][ct_barrett-1] <= mult_reg[ct_barrett-1];
                      outState[1][ct_barrett-1] <= pow_5_reg[ct_barrett-1];
                      mult1_num1 <= sum_reduced;
                      mult1_num2 <= sum_reduced;
                      mult2_num1 <= sum_reduced;
                      mult2_num2 <= precompute_reg[ct_barrett-1];
                 	 ct_barrett <= ct_barrett + 1;
                if(ct_barrett == 13) ct_barrett <= 0;
              end
          end


			COMPUTE_OTHERS: begin
             case (ct_step)
                0: begin
                 // if (y0_rd) begin
                //$display("outState[0] = %h", outState[0]);
                //$display("outState[1] = %h", outState[1]);
                   // y0_rd <= 0;
                 // end
                    // Register updates
                    ct_barrett <= ct_barrett + 1;
                    mult1_num1 <= mult1_result;
                    mult1_num2 <= x2_reg[ct_barrett];
                    mult2_num1 <= x2_reg[ct_barrett];
                    mult2_num2 <= BETA;
                    kL[ct_barrett] <= mult2_result;

                    if (ct_barrett == 12) begin
                        ct_step <= ct_step + 1;
                        ct_barrett <= 0;
                    end
                end
                1: begin
                  	//y2_rd <= 1;
                    // Register updates
                   // $display("1:ct_barrett = %d", ct_barrett);
                    ct_barrett <= ct_barrett + 1;
                    add_num1 <= kL[ct_barrett];
                    add_num2 <= mult1_result;
                    add_num3 <= mult2_result;
                  	
                 	 //if (y2_rd) begin
                   // $display("outState[2] is %h",add_sum);
                  	//end
                    if (ct_barrett > 0) begin
                    
                        outState[2][ct_barrett-1] <= add_sum;
                    end
                  if (ct_barrett == 12) begin
                        compute_others_done <= 1;
                    end
                end
                endcase
            end


            DONE: begin
                done <= 1;
//                 for (int i = 0; i < STATE_SIZE; i++) begin
//                   for (int j = 0; j < 13; j++) $display("nonlinear_out[%1d][%1d]=%h ", i, j, outState[i][j]);
                //end
              //$display("outState[2] is %h", outState[2]);
            end
        endcase
    end
  assign mult_result_ready = mult_result_ready_reg[12];
  assign pow_result_ready = pow_result_ready_reg[12];
  assign precomputation_result_ready = precomputation_result_ready_reg[12];



  always_latch begin
        if (pow_result_ready) pow_5_reg[ct_barrett] <= mult1_result;
        if (mult_result_ready) mult_reg[ct_barrett] <= mult1_result;
        if (precomputation_result_ready) precompute_reg[ct_barrett] <= mult1_result;
    end

    always_ff @(posedge clk) begin
    // Unrolling for mult_result_ready_reg
    mult_result_ready_reg[1] <= mult_result_ready_reg[0];
    mult_result_ready_reg[2] <= mult_result_ready_reg[1];
    mult_result_ready_reg[3] <= mult_result_ready_reg[2];
    mult_result_ready_reg[4] <= mult_result_ready_reg[3];
    mult_result_ready_reg[5] <= mult_result_ready_reg[4];
    mult_result_ready_reg[6] <= mult_result_ready_reg[5];
    mult_result_ready_reg[7] <= mult_result_ready_reg[6];
    mult_result_ready_reg[8] <= mult_result_ready_reg[7];
    mult_result_ready_reg[9] <= mult_result_ready_reg[8];
    mult_result_ready_reg[10] <= mult_result_ready_reg[9];
    mult_result_ready_reg[11] <= mult_result_ready_reg[10];
    mult_result_ready_reg[12] <= mult_result_ready_reg[11];
    // Unrolling for pow_result_ready_reg
    pow_result_ready_reg[1] <= pow_result_ready_reg[0];
    pow_result_ready_reg[2] <= pow_result_ready_reg[1];
    pow_result_ready_reg[3] <= pow_result_ready_reg[2];
    pow_result_ready_reg[4] <= pow_result_ready_reg[3];
    pow_result_ready_reg[5] <= pow_result_ready_reg[4];
    pow_result_ready_reg[6] <= pow_result_ready_reg[5];
    pow_result_ready_reg[7] <= pow_result_ready_reg[6];
    pow_result_ready_reg[8] <= pow_result_ready_reg[7];
    pow_result_ready_reg[9] <= pow_result_ready_reg[8];
    pow_result_ready_reg[10] <= pow_result_ready_reg[9];
    pow_result_ready_reg[11] <= pow_result_ready_reg[10];
    pow_result_ready_reg[12] <= pow_result_ready_reg[11];
    // Unrolling for precomputation_result_ready_reg
    precomputation_result_ready_reg[1] <= precomputation_result_ready_reg[0];
    precomputation_result_ready_reg[2] <= precomputation_result_ready_reg[1];
    precomputation_result_ready_reg[3] <= precomputation_result_ready_reg[2];
    precomputation_result_ready_reg[4] <= precomputation_result_ready_reg[3];
    precomputation_result_ready_reg[5] <= precomputation_result_ready_reg[4];
    precomputation_result_ready_reg[6] <= precomputation_result_ready_reg[5];
    precomputation_result_ready_reg[7] <= precomputation_result_ready_reg[6];
    precomputation_result_ready_reg[8] <= precomputation_result_ready_reg[7];
    precomputation_result_ready_reg[9] <= precomputation_result_ready_reg[8];
    precomputation_result_ready_reg[10] <= precomputation_result_ready_reg[9];
    precomputation_result_ready_reg[11] <= precomputation_result_ready_reg[10];
    precomputation_result_ready_reg[12] <= precomputation_result_ready_reg[11];
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

  	galois_add_three#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) add_three_instance (
        .num1(add_num1),
        .num2(add_num2),
        .num3(add_num3),
        .sum(add_sum)
    );
    
endmodule