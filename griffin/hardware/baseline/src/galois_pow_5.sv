// Module that performs exponentiation to the power of 5, on an element in Galois Field with Prime order.

// Uses 2 galois mult instances and takes time equivalent to 3 modular multiplications.

// Pipelined design: supports multiple in-flight computations.
//     - Latency: 39 clock cycles (including the cycle in which inputs are injected).
//     - Pipeline length: 39 clock cycles.
//     - Accepts new request in each of the first 13 clock cycles in every 39-clock-cycle period.

module galois_pow_5 #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925 // Size: N_BITS + 1
) (
    input clk, reset, enable,
    input  [N_BITS-1:0] base,
  	output logic [N_BITS-1:0] result,
	output logic done
);
	localparam BARRETT_LATENCY = 12;
	logic [N_BITS-1:0] num1;
	logic [N_BITS-1:0] num2;
  	logic [N_BITS-1:0] product;
	logic [4:0] ct;
	enum logic[3:0] {INIT, COMPUTE_A, COMPUTE_B, COMPUTE_C, DONE} state, next_state;
	always_ff @( posedge clk ) begin
		if (reset) state <= INIT;
		else state <= next_state;
	end
	always_comb begin
		case (state)
			INIT: next_state = enable? COMPUTE_A: INIT;
			COMPUTE_A: next_state = (ct == 12)? COMPUTE_B:COMPUTE_A;
			COMPUTE_B: next_state = (ct==12)? COMPUTE_C: COMPUTE_B;
			COMPUTE_C: next_state = (ct==12)? DONE: COMPUTE_C;
			DONE: next_state = INIT; 
			default: next_state = INIT;
		endcase
	end
	always_ff@(posedge clk) begin
		case (state)
			INIT: begin
				num1 <= 0;
				num2 <= 0;
				done <= 0;
				ct <= 0;
			end
			COMPUTE_A: begin
				if (ct == 12) ct <= 0;
				else ct <= ct + 1;
				//compute x * x
				num1 <= base;
				num2 <= base;
			end 
			COMPUTE_B: begin
				if (ct == 12) ct <= 0;
				else ct <= ct + 1;
				//compute x^2 * x^2
				num1 <= product;
				num2 <= product;
			end
			COMPUTE_C: begin
				if (ct == 12) ct <= 0;
				else ct <= ct + 1;
				num1 <= product;
				num2 <= base;
			end
			DONE: begin
				done <= 1;
				result <= product;
			end
		endcase
	end
galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) multiplier_instantce (
	.clk(clk),
	.num1(num1),
	.num2(num2),
	.product(product)
);
endmodule
