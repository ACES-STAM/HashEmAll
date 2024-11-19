module tb_galois_pow_dinv;

    // Parameters
    parameter N_BITS = 254;
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925;

    // Signals
  reg [N_BITS-1:0] base, base1;
    reg clk, reset, enable;
  wire [N_BITS-1:0] result,result1;
    wire done;
  reg [N_BITS-1:0] correct, correct1;
    // Clock generation (50MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz clock
    end

    // Instantiate the DUT (Design Under Test)
    galois_pow_dinv #(
        .N_BITS(N_BITS),
        .PRIME_MODULUS(PRIME_MODULUS),
        .BARRETT_R(BARRETT_R)
    ) dut (
        .base(base),
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .result(result),
      .done(done),
      .base1(base1),
      .result1(result1)
    );

    // Test Sequence
    initial begin
      
      $dumpfile("tb_galois_pow_dinv.vcd");
      $dumpvars(0,tb_galois_pow_dinv);
      correct = 254'hd6e94e8a65d3deaf248dc7ce28bd2e96ad00fffef8eabb83c601dc64e00b4d6;
      correct1 = 254'h851f9517dcd8762df1a2a823fdb84b50b1b15122c07a2f7cc723b74ae28626c;
        // Initialize inputs
        base = 254'h1;
        reset = 1;
        enable = 0;
        
        // Apply reset
        #20 reset = 0;

        // Apply enable and base input
        #10 base = 254'h2e7246c320355b8b9053b6e60b0eba343af3066737c38b2324cdb3932533a2c8;
      base1 =254'h0d62e11b4392bb8b7f1f2c9f5a8f94dee8d1e690944359498788e1849a5ca3bc;
        enable = 1;
        #100 enable = 0;
        // Wait for done signal
        wait (done);
      #500
      
        // Check the result
      if (result == correct && result1 == correct1) $display("Test Passed");
      else $display("Test Failed");
        // End simulation
        #100 $stop;
    end

endmodule
