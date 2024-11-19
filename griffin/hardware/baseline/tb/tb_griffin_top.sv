module tb_griffin_top();

    // Parameters
    parameter N_BITS = 254;
    parameter STATE_SIZE = 3;
    
    // Inputs to the DUT (griffin_top)
    reg clk;
    reg reset;
    reg enable;
    reg wr;
    reg [N_BITS-1:0] inState;
	reg rd;
    // Outputs from the DUT
    wire [N_BITS-1:0] outState;
    wire done, rd_done;

    // Internal signals
    reg [N_BITS-1:0] input_data [STATE_SIZE-1:0]; // 3 inputs
    reg [31:0] enable_time, done_time; // Store timestamps

    // Instantiate the DUT
    griffin_top #(
        .N_BITS(N_BITS),
        .STATE_SIZE(STATE_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .wr(wr),
        .rd(rd),
        .inState(inState),
        .outState(outState),
        .done(done),
        .rd_done(rd_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10 ns period)
    end

    // Testbench process
    initial begin
        // Initialize input data
        input_data[0] = 254'h2fac35e0defc28a1d94166f346928568ab7d6ff10c12e1e3cd87f5a5af9c77f8;
        input_data[1] = 254'h2cd889b5cd1564eecffc6954299a0271050d9b71916f708ca629bde622602de7;
        input_data[2] = 254'h095bf664ddb90c6a06e9bcd438d36adf45af6f1913862123f09a350c57cb5e4f;

        // Initialize signals
        reset = 1;
        wr = 0;
        inState = 0;
        enable = 0;
        enable_time = 0;
        done_time = 0;

        // Apply reset
        #10 reset = 0;

        // Enable write and start feeding input data continuously without toggling wr
        wr = 1;
        for (int i = 0; i < STATE_SIZE; i++) begin
            @(negedge clk); 
            inState = input_data[i];
        end
      
        @(negedge clk); 
        wr = 0;
      
        #20;

        // Start computation by enabling the DUT
        enable = 1;
        enable_time = $time; // Capture the time when enable is asserted
        #20 enable = 0;
      
        // Wait for 'done' signal
        wait(done);
        done_time = $time; // Capture the time when done goes high

        // Calculate and display the time difference
        $display("Time from enable to done: %0d ns", done_time - enable_time);
      
        // Proceed with reading the output
        #10 rd = 1;
        wait(rd_done);
        #100 $stop;
    end

    initial begin
        // Monitor the outState continuously whenever rd is active
        $monitor("At time %0t: outState = %h", $time, outState);
    end

endmodule
