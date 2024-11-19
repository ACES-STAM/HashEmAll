// EDA playground link: https://www.edaplayground.com/x/n6WC

module griffinPi #(
    parameter N_BITS = 254,
	parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3
) (
    input clk, reset, enable,
    input [N_BITS-1:0] inState[STATE_SIZE], 
    input [N_BITS-1:0] round_constants[STATE_SIZE],
    output logic [N_BITS-1:0] outState[STATE_SIZE],
    output logic done
);

enum logic[1:0] {INIT, NONLINEAR, LINEAR, DONE} state, next_state;
logic [N_BITS-1:0] state_in_nonlinear[STATE_SIZE], state_out_nonlinear[STATE_SIZE];
logic [N_BITS-1:0] state_in_linear[STATE_SIZE], state_out_linear[STATE_SIZE];
logic enable_nonlinear, nonlinear_done;
logic nonlinear_start;
logic linear_done;
always_ff@(posedge clk) begin
  //$display("GRIFFIN-PI current state is %d, next state is %d", state, next_state);
        //$display("enable_nonlinear is %d", enable_nonlinear);
    if (reset) state <= INIT;
    else state <= next_state;

end

always_comb begin 
    case (state)
        INIT: next_state = enable? NONLINEAR: INIT;
        NONLINEAR: next_state = nonlinear_done? LINEAR: NONLINEAR;
        LINEAR: next_state = linear_done? DONE:LINEAR;
        DONE: next_state = INIT;
        default: next_state = INIT;
    endcase
end

always_ff @( posedge clk ) begin
    case (state)
        INIT: begin
            linear_done <= 0;
            done <= 0;
            enable_nonlinear <= 0;
          	nonlinear_start <= 1;
        end
        NONLINEAR: begin
          if (nonlinear_start) begin
            enable_nonlinear <= 1;
            for (int i = 0; i < STATE_SIZE; i++) begin
                state_in_nonlinear[i] <= inState[i];
            end
            nonlinear_start <= 0;
          end
          else enable_nonlinear <= 0;
        end
        LINEAR: begin
            enable_nonlinear <= 0;
          	if (!linear_done) begin 
              for(int i = 0; i < STATE_SIZE; i++) begin
                  state_in_linear[i] <= state_out_nonlinear[i];
              end
         	end
            linear_done <= 1;
        end
        DONE: begin
           for(int i = 0; i < STATE_SIZE; i++) begin
                outState[i] <= state_out_linear[i];
             //$display("outState[i] is %h", state_out_linear[i]);
           end 
          done <= 1;
        end 
    endcase
end
  affine_3#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .STATE_SIZE(STATE_SIZE)) affine_layer(
    .clk(clk),
    .inState(state_in_linear),
    .round_constants(round_constants),
    .outState(state_out_linear)
);
nonlinear#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .STATE_SIZE(STATE_SIZE), .BARRETT_R(BARRETT_R)) s_box(
    .inState(state_in_nonlinear),
    .clk(clk),
    .reset(reset),
    .enable(enable_nonlinear),
    .outState(state_out_nonlinear),
    .done(nonlinear_done)
);
endmodule