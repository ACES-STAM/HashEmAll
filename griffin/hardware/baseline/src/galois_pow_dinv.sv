module galois_pow_dinv #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925 // Size: N_BITS + 1
) (
    input [N_BITS-1:0] base,
    input [N_BITS-1:0] base1,
    input clk, reset, enable,
    output logic [N_BITS-1:0] result,
    output logic [N_BITS-1:0] result1,
    output logic done
);
    localparam BARRETT_LATENCY = 12;
    localparam DINV = 254'h26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd;
    
    enum logic[1:0] {INIT, COMPUTE, DONE} state, next_state;
    logic [N_BITS-1:0] dinv;
    logic [N_BITS-1:0] mult_num1; 
    logic [N_BITS-1:0] mult_num2; 
    logic [N_BITS-1:0] square_num1; 
    logic [N_BITS-1:0] square_num2; 
    logic [N_BITS-1:0] mult_result, mult_result_reg, pow_5_reg;
    logic [N_BITS-1:0] square_result;
    logic mult_flag, mult_result_ready, pow_result_ready;
    logic [3:0] ct_barrett, ct_power;
    logic compute_start, compute_done, pow_5_start, pow_5_done;
    assign mult_flag = dinv & 1'b1;
  assign compute_done = (|dinv)? 0:1;
  
    always_ff@(posedge clk) begin
      //$display("current state is %d, next state is %d", state, next_state);
        if(reset) state <= INIT;
        else state <= next_state;
    end
    
    always_comb begin
        case (state)
            INIT: next_state = enable? COMPUTE: INIT;
            COMPUTE: next_state = compute_done? DONE:COMPUTE;
            DONE: next_state = INIT; 
            default: next_state = INIT;
        endcase
    end
  
  	always_ff@(posedge clk) begin
        case (state)
            INIT: begin
                dinv <= DINV;
                ct_barrett <= 0;
                compute_start <= 1;
                pow_5_start <= 1;
                done <= 0;
                mult_result_ready <= 0;
                ct_power <= 0;
                pow_5_done <= 0;
            end 
            COMPUTE: begin
//               $display("dinv is %h", dinv);
//               $display("ct_barrett is %d", ct_barrett);
               compute_start <= 0;
              if (ct_barrett == 12) begin
                dinv <= dinv >> 1;
                ct_barrett <= 0;
              end
              
              else if (ct_barrett == 0 && !compute_done) begin
                	ct_barrett <= ct_barrett + 1;
                  	if (mult_flag) begin
                        mult_result_ready <= 1;
                        pow_result_ready <= 0;
                        if (compute_start) begin
                            mult_num1 <= 1;
                            mult_num2 <= base;
                            square_num1 <= base;
                            square_num2 <= base;
                        end
                        else begin
                            mult_num1 <= mult_result_reg;
                            mult_num2 <= square_result;
                            square_num1 <= square_result;
                            square_num2 <= square_result;
                        end
                    end
                    else begin
                        mult_result_ready <= 0;
                      if (ct_power < 4) begin
                            ct_power <= ct_power + 1;
                            pow_result_ready <= 1;
                            if (pow_5_start) begin
                                pow_5_start <= 0;
                                mult_num1 <= base1;
                                mult_num2 <= base1;
                            end
                            else begin
                                mult_num1 <= base1;
                                mult_num2 <= pow_5_reg;
                            end
                        end
                        else pow_result_ready <= 0;
                        square_num1 <= square_result;
                        square_num2 <= square_result;
                    end                    
              end
              
              else begin
                if (!compute_done) ct_barrett <= ct_barrett + 1;
              end

            end
            DONE: begin
                result <= mult_result; 
                done <= 1;
                result1 <= pow_5_reg;
            end
        endcase
    end

    always_latch begin
        if (pow_result_ready) pow_5_reg <= mult_result;
        if (mult_result_ready) mult_result_reg = mult_result;
    end

    galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult_instance(
        .clk(clk),
        .num1(mult_num1),
        .num2(mult_num2),
        .product(mult_result)
    );

    galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) square_instance(
        .clk(clk),
        .num1(square_num1),
        .num2(square_num2),
        .product(square_result)
    );
endmodule