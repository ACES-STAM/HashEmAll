module tb_nonlinear;

    // Parameters
    parameter N_BITS = 254;
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    parameter STATE_SIZE = 3;

    // Testbench Signals
  reg [N_BITS-1:0] inState [STATE_SIZE];
    reg clk, reset, enable;
    wire [N_BITS-1:0] outState [STATE_SIZE];
    wire done;

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // DUT (Device Under Test) instantiation
    nonlinear #(
        .N_BITS(N_BITS),
        .PRIME_MODULUS(PRIME_MODULUS),
        .STATE_SIZE(STATE_SIZE)
    ) uut (
        .inState(inState),
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .outState(outState),
        .done(done)
    );

    // Test vectors (inputs provided)
    initial begin
      $dumpfile("tb_nonlinear.vcd");
      $dumpvars(0,tb_nonlinear);
        // Initialize Inputs
        inState[0] = 254'h2e7246c320355b8b9053b6e60b0eba343af3066737c38b2324cdb3932533a2c8; // FpBN254(0x2e7246c320355b8b9053b6e60b0eba343af3066737c38b2324cdb3932533a2c8)
        inState[1] = 254'h0d62e11b4392bb8b7f1f2c9f5a8f94dee8d1e690944359498788e1849a5ca3bc; // FpBN254(0x0d62e11b4392bb8b7f1f2c9f5a8f94dee8d1e690944359498788e1849a5ca3bc)
        inState[2] = 254'h21f85ecc42eb9217f1045c81b6794fbf2bf5f1912ff55bb1397f997e8050012a; // FpBN254(0x21f85ecc42eb9217f1045c81b6794fbf2bf5f1912ff55bb1397f997e8050012a)
        
        reset = 1;
        enable = 0;
        #10 reset = 0;
        enable = 1;
    end
/* Non-linear function output: [FpBN254(0x0d6e94e8a65d3deaf248dc7ce28bd2e96ad00fffef8eabb83c601dc64e00b4d6), FpBN254(0x0851f9517dcd8762df1a2a823fdb84b50b1b15122c07a2f7cc723b74ae28626c), FpBN254(0x228ca266b036a1de8283bb4c2ba783dc1726cd1c0f7f37b5637ae722de4f8d2c)]
*/
    // Monitor the output only when done
    always_ff @(posedge clk) begin
        if (done) begin
            $display("Output after done signal:");
            $display("outState[0] = %h", outState[0]);
            $display("outState[1] = %h", outState[1]);
            $display("outState[2] = %h", outState[2]);
            $finish;
        end
    end

endmodule
