module tb_galois_pow_5;
  
  // Parameters
  localparam N_BITS = 254;
  localparam PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
  localparam BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925;

  // Clock and reset
  logic clk;
  logic reset;
  logic enable;
  
  // Inputs and outputs
  logic [N_BITS-1:0] base;
  logic [N_BITS-1:0] result;
  logic done;
  
  // Expected result: 2^5 mod PRIME_MODULUS
  logic [N_BITS-1:0] expected_result;
  assign expected_result = 254'h20;  // 2^5 = 32 (0x20 in hex)

  // DUT instantiation
  galois_pow_5 #(
    .N_BITS(N_BITS),
    .PRIME_MODULUS(PRIME_MODULUS),
    .BARRETT_R(BARRETT_R)
  ) dut (
    .clk(clk),
    .reset(reset),
    .enable(enable),
    .base(base),
    .result(result),
    .done(done)
  );
  
  // Clock generation
  always #5 clk = ~clk;  // 100 MHz clock period (10ns)

  // Test sequence
  initial begin
    $dumpfile("tb_galois_pow_5.vcd");
    $dumpvars(0,tb_galois_pow_5);
    // Initialize inputs
    clk = 0;
    reset = 1;
    enable = 0;
    base = 0;
    
    // Apply reset
    #10;
    reset = 0;

    // Test case: Smaller base value (base = 2)
    @(posedge clk);
    base = 254'h0000000000000000000000000000000000000000000000000000000000000002;  // Small base value: 2
    enable = 1;

    // Wait for the module to finish the computation
    wait(done == 1);
    
    // Display the result and check correctness
    if (result == expected_result)
      $display("Test Passed: Base = 0x%h, Result = 0x%h", base, result);
    else
      $display("Test Failed: Base = 0x%h, Expected = 0x%h, Got = 0x%h", base, expected_result, result);

    // End of simulation
    #10;
    $stop;
  end

endmodule
