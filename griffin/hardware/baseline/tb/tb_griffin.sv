module tb_griffin;

    // Parameters from the original design
    parameter N_BITS = 254;
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925;
    parameter STATE_SIZE = 3;
    parameter NUM_ROUNDS = 14;

    // Test signals
    reg clk, reset, enable;
    reg [N_BITS-1:0] inState [STATE_SIZE];
    wire [N_BITS-1:0] outState [STATE_SIZE];
    wire done;
    reg [N_BITS-1:0] correct [STATE_SIZE];

    // Instantiate the griffin module
    griffin #(
        .N_BITS(N_BITS),
        .PRIME_MODULUS(PRIME_MODULUS),
        .BARRETT_R(BARRETT_R),
        .STATE_SIZE(STATE_SIZE),
        .NUM_ROUNDS(NUM_ROUNDS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .inState(inState),
        .outState(outState),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns clock period

    initial begin
        $dumpfile("tb_griffin.vcd");
        $dumpvars(0, tb_griffin);

        // Initialize signals
        clk = 0;
        reset = 1;
        enable = 0;

        // Initialize inputs (provided FpBN254 values)
        inState[0] = 254'h0957aed78044d6eacf2fb78ae9a746eaf34de8ae144953374b6255630f7fc50d;
        inState[1] = 254'h0d3798d6a886e553395ba0f5e9902b224322b53edc8cd613fccd55a0c2f3fb8f;
        inState[2] = 254'h1adea8af995a36dd5eec879efd3bcecffc635e250a94adb08d1be6ef88f5eba6;

        // Expected output (correct result)
        correct[0] = 254'h0396c8e252617d93bcc81ed4bc84f3237872cffc14e1fcde3339413324c6eac8;
        correct[1] = 254'h103eb80dde27eb4ade997f25e7b40ced8aaf0e1de9a6f77ecd6250bd91c79b48;
        correct[2] = 254'h2f87c2186c3322395a344f04ab83e0e364e70b66403dceaa232f66107e5874eb;

        // Apply reset
        #10 reset = 0; // Release reset
        #10 enable = 1; // Start the operation

        // Wait for the operation to complete
        wait(done);

        // Compare the output with the expected values
        $display("Output State:");
        for (int i = 0; i < STATE_SIZE; i++) begin
            $display("outState[%0d]: %h", i, outState[i]);
        end

        // Check if the output matches the expected result
        if ((outState[0] == correct[0]) && (outState[1] == correct[1]) && (outState[2] == correct[2])) begin
            $display("PASS: Output matches the expected result.");
        end else begin
            $display("FAIL: Output does not match the expected result.");
        end

        // Finish simulation
        $finish;
    end
endmodule
