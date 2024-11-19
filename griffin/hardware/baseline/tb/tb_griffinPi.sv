module tb_griffinPi;

    // Parameters
    parameter N_BITS = 254;
    parameter STATE_SIZE = 3;
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925;

    // Testbench signals
    reg clk, reset, enable;
    reg [N_BITS-1:0] inState[STATE_SIZE];
    reg [N_BITS-1:0] round_constants[STATE_SIZE];
    wire [N_BITS-1:0] outState[STATE_SIZE];
    wire done;

    // Instantiate the DUT (Device Under Test)
    griffinPi #(
        .N_BITS(N_BITS),
        .PRIME_MODULUS(PRIME_MODULUS),
        .BARRETT_R(BARRETT_R),
        .STATE_SIZE(STATE_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .inState(inState),
        .round_constants(round_constants),
        .outState(outState),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test stimulus
    initial begin
      $dumpfile("tb_griffinPi.vcd");
      $dumpvars(0,tb_griffinPi);
        // Initialize inputs
        reset = 1;
        enable = 0;

        // Round 0 constants
        round_constants[0] = 254'h2fb30cafdb1f76156dfabf0cd0af4b895e764ac2a84386c9d0d7aed6a7f4eac9;
        round_constants[1] = 254'h282927892ce324572f19abb14871d2b539a80d8a5800cdb87a81e1697a94b6c9;
        round_constants[2] = 254'h03d0f3f2711dd59e3d97fc797261300cd3fee33b95cf710a32edf42aa2bc0905;

        // Input state (inState) provided from image
        inState[0] = 254'h0a6150c2613929dc7e5751f438992f6afdedfc7795fab9a1dccbf1c27ae9714e;
        inState[1] = 254'h0e413ac1897b3844e8833b5f388213a24dc2c9085e3e3c7e8e36f2002e5da7d0;
        inState[2] = 254'h1be84a9a7a4e89cf0e1422084c2db750070371ee8c46141b1e85834ef45f97e7;

        // Reset pulse
        #10 reset = 0;

        // Enable the operation
        #10 enable = 1;
		#20 enable = 0;
        // Wait for 'done' signal
        wait (done);
        $display("Griffin-Pi Output:");
        $display("outState[0] = %h", outState[0]);
        $display("outState[1] = %h", outState[1]);
        $display("outState[2] = %h", outState[2]);

        // End simulation
        #10 $finish;
    end



endmodule
