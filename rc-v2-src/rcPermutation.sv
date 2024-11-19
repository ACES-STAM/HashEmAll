module rcPermutation #(
    parameter STATE_SIZE = 3,
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925 // Size: N_BITS + 1
) (
    input [N_BITS-1:0] inState[STATE_SIZE][13],
    input clk, reset, enable,
    output logic [N_BITS-1:0] outState[STATE_SIZE][13],
    output logic done
);
logic [255:0] ROUND_CONSTANTS [24];

    initial begin
        ROUND_CONSTANTS[0]  = 256'd5748013;
        ROUND_CONSTANTS[1]  = 256'd8959805;
        ROUND_CONSTANTS[2]  = 256'd5322109;

        ROUND_CONSTANTS[3]  = 256'd9833447;
        ROUND_CONSTANTS[4]  = 256'd8565022;
        ROUND_CONSTANTS[5]  = 256'd7968812;

        ROUND_CONSTANTS[6]  = 256'd15008204;
        ROUND_CONSTANTS[7]  = 256'd15007603;
        ROUND_CONSTANTS[8]  = 256'd9832189;

        ROUND_CONSTANTS[9]  = 256'd2114001;
        ROUND_CONSTANTS[10] = 256'd5269258;
        ROUND_CONSTANTS[11] = 256'd11741327;

        ROUND_CONSTANTS[12] = 256'd1743068;
        ROUND_CONSTANTS[13] = 256'd2860587;
        ROUND_CONSTANTS[14] = 256'd10360691;

        ROUND_CONSTANTS[15] = 256'd3644088;
        ROUND_CONSTANTS[16] = 256'd5132511;
        ROUND_CONSTANTS[17] = 256'd15861760;

        ROUND_CONSTANTS[18] = 256'd11168023;
        ROUND_CONSTANTS[19] = 256'd2253203;
        ROUND_CONSTANTS[20] = 256'd14099134;

        ROUND_CONSTANTS[21] = 256'd1160717;
        ROUND_CONSTANTS[22] = 256'd14097647;
        ROUND_CONSTANTS[23] = 256'd6717918;
    end
    localparam S1 = 254'd12345678901234567890;
    localparam S2 = 254'd98765432109876543210;
    localparam S3 = 254'd11223344556677889900;
    localparam S4 = 254'd99887766554433221100;
    localparam S5 = 254'd31415926535897932384;  // 31415926535897932384
    localparam LUT_S2_UPPER = 256'hBF417EE5777B1DCC23ED56586F15686619A1FAABC3895C4894A938A5F3E6950;
    localparam LUT_S2_LOWER = 190'h624E8E16FE8C9513C36C257F3AF192DA5BCF48384465EBD;
    localparam LUT_S3_UPPER = 256'h6930D2980157495CC32BB2D4C6530ED97FA0B559F1CC7E0973FE934792A5F184;
    localparam LUT_S3_LOWER = 190'h3A8B5DE244A35F7CE819260EE8ADAB61905A7B0B840F1C3A;
    localparam LUT_S4_UPPER = 256'hBD1B5DD4DD0477DAACE27ADD7E0E8AF5D346A682930091655D190E245F33723;
    localparam LUT_S4_LOWER = 190'h1F76EB6EFD6546387A2784CFB0581E0A2B98DF707A1FA94D;
    localparam LUT_S5_UPPER = 256'h25945374CFC8DEF339FF3CA911892615CF53A85735C67FF1F0F0D0BCBB735033;
    localparam LUT_S5_LOWER = 190'h206B6745CF5354BD36C31A8DF77901E6645E3CF6B4B04B17;
    localparam COEF_3 = 197'h11a3a6a4adec60d2f8c637baa1f1a7b2c254b6ec7b0d4d61a0; //S2*S3*S4
    localparam COEF_4 =254'h2c852b6b9b39cbd0493fd6383a31e916192afd93584c8cebe14d29db1cf3db62;

typedef enum logic[4:0] {INIT, CONCRETE1,CONCRETE2,BRICKS1,BRICKS2,BRICKS3,BAR_DECOMP1,BAR_DECOMP2, BAR_DECOMP3, BAR_DECOMP4, 
BAR_COMP1,BAR_COMP2, BAR_COMP3, DONE, IDLE} state_t;
localparam MULT = 0;
localparam COMPOSE =1 ;
localparam DECOMPOSE = 2;
state_t state, next_state;
logic [3:0] ct_barrett;
logic [1:0] sel;
logic [256-1:0] mult1_num1, mult1_num2, mult2_num1, mult2_num2, mult3_num1, mult3_num2;
logic [N_BITS-1:0] x_decompose1, x_decompose2, x_decompose3;
logic [189:0] s_lower;
logic [66:0] s_next;
logic [N_BITS-1:0] mult1_product, mult2_product, mult3_product;
logic [198:0] composed1, composed2, composed3;
logic [69:0] d1, d2, d3;
logic [69:0] d1_1[13], d1_2[13], d1_3[13], d1_4[13], d1_5[13];
logic [69:0] d2_1[13], d2_2[13], d2_3[13], d2_4[13], d2_5[13];
logic [69:0] d3_1[13], d3_2[13], d3_3[13], d3_4[13], d3_5[13];
logic [191:0] r_reg1, r_reg2, r_reg3;
logic [2:0] ct_concrete;
logic brick_done, decomp_done, comp_done, concrete_done;
logic [N_BITS-1:0] concrete_in[STATE_SIZE], concrete_out[STATE_SIZE], round_constants[STATE_SIZE];
logic [N_BITS-1:0] x1_reg[13], x2_reg[13], x3_reg[13];
logic [N_BITS-1:0] y2_partial[13], y3_partial[13];
logic [N_BITS-1:0] add3_num1, add3_num2, add3_num3, add3_sum;
logic [N_BITS-1:0] add2_num1, add2_num2, add2_sum;
logic [N_BITS-1:0] add1Num1, add1Num2, add2Num1, add2Num2, add3Num1, add3Num2, add1Sum, add2Sum, add3Sum;
logic[N_BITS-1:0] sum1_reg[13], sum2_reg[13], sum3_reg[13];

    function automatic logic [N_BITS-1:0] galois_add_three (
    input logic [N_BITS-1:0] num1,
    input logic [N_BITS-1:0] num2,
    input logic [N_BITS-1:0] num3,
    input logic [N_BITS-1:0] PRIME_MODULUS
    );
    logic [(N_BITS+2)-1:0] temp;
    logic signed [(N_BITS+2)-1:0] temp1;
    logic signed [(N_BITS+2)-1:0] temp2;
      //$display("input is %h, %h, %h", num1, num2, num3);
    temp = num1 + num2 + num3;
    temp1 = temp - PRIME_MODULUS;
    temp2 = temp - 2 * PRIME_MODULUS;

    if (temp2 >= 0)
        galois_add_three = temp2[N_BITS-1:0];
    else if (temp1 >= 0)
        galois_add_three = temp1[N_BITS-1:0];
    else
        galois_add_three = temp[N_BITS-1:0];
    endfunction

    function automatic logic [N_BITS-1:0] galois_add_two (
    input logic [N_BITS-1:0] num1,
    input logic [N_BITS-1:0] num2,
    input logic [N_BITS-1:0] PRIME_MODULUS
    );
    logic [(N_BITS+1)-1:0] temp1;
    logic signed [(N_BITS+1)-1:0] temp2;
   // $display("input is %h, %h", num1, num2);
    temp1 = num1 + num2;
    temp2 = temp1 - PRIME_MODULUS;

    if (temp2 >= 0)
        galois_add_two = temp2[N_BITS-1:0];
    else
        galois_add_two = temp1[N_BITS-1:0];
    endfunction


always_ff @( posedge clk ) begin
 // $display("state is %d, next state is %d", state, next_state);
    if (reset) state <= INIT;
    else state <= next_state;
end

always_comb begin
    case (state)
        INIT: next_state =  enable? CONCRETE1: INIT;
        CONCRETE1: next_state = CONCRETE2;
        CONCRETE2: begin
            if (ct_concrete == 3) next_state = BAR_DECOMP1;
            else if (ct_concrete == 7) next_state = DONE;
            else next_state = BRICKS1;
        end
        BRICKS1: begin 
            sel = MULT;
            next_state = (ct_barrett == 12)? BRICKS2: BRICKS1;
        end
        BRICKS2: begin
            sel = MULT;
            next_state = (ct_barrett==12)? BRICKS3:BRICKS2;
        end
        BRICKS3: begin
            sel = MULT;
            next_state = (ct_barrett == 12)? CONCRETE1: BRICKS3;
        end
        BAR_DECOMP1: begin
            sel = DECOMPOSE;
            next_state = (ct_barrett == 12)? BAR_DECOMP2: BAR_DECOMP1;
        end
        BAR_DECOMP2: begin
            sel = DECOMPOSE;
            next_state = (ct_barrett == 12)? BAR_DECOMP3:BAR_DECOMP2;
        end
        BAR_DECOMP3: begin
            next_state = (ct_barrett == 12)? BAR_DECOMP4: BAR_DECOMP3;
            sel = DECOMPOSE;
        end
        BAR_DECOMP4: begin
            sel = DECOMPOSE;
            next_state = (ct_barrett == 12)? BAR_COMP1: BAR_DECOMP4;
        end
        BAR_COMP1: begin
            next_state = (ct_barrett == 12)? BAR_COMP2:BAR_COMP1;
            sel = COMPOSE;
        end
        BAR_COMP2: begin
            sel = MULT;
            next_state = (ct_barrett == 12)? BAR_COMP3: BAR_COMP2;
        end
        BAR_COMP3: begin
            sel = MULT;
            next_state = (ct_barrett == 12)? CONCRETE1:BAR_COMP3;
        end
        DONE: next_state = (ct_barrett == 12)? IDLE:DONE; 
        IDLE: next_state = IDLE;
        default: next_state = INIT;
    endcase
end

always_ff @( posedge clk ) begin
    case (state)
        INIT: begin
            done <= 0;
            ct_barrett <= 0;
            ct_concrete <= 0;
            ct_barrett <= 0;
        end 
        CONCRETE1:begin
//           $display("round_constants = %d, %d, %d",ROUND_CONSTANTS[3*ct_concrete],ROUND_CONSTANTS[3*ct_concrete+1], ROUND_CONSTANTS[3*ct_concrete+2]);
            round_constants[0] <= ROUND_CONSTANTS[3*ct_concrete];
            round_constants[1] <= ROUND_CONSTANTS[3*ct_concrete+1];
            round_constants[2] <= ROUND_CONSTANTS[3*ct_concrete+2];
            if (ct_concrete == 0) begin
             // $display("input to concrete: %d,%d,%d", inState[0][ct_barrett],inState[1][ct_barrett],inState[2][ct_barrett]);
              concrete_in[0] <= inState[0][ct_barrett];
              concrete_in[1] <= inState[1][ct_barrett];
              concrete_in[2] <= inState[2][ct_barrett];
            end
            else if (ct_concrete == 4) begin
               // $display("ct_concrete = %1d, input is %d, %d, %d", ct_concrete, add1Sum, add2Sum, add3Sum);
                concrete_in[0] =  galois_add_two(mult1_product, sum1_reg[0], PRIME_MODULUS);
                concrete_in[1] =  galois_add_two(mult2_product, sum2_reg[0], PRIME_MODULUS);
                concrete_in[2] =  galois_add_two(mult3_product, sum3_reg[0], PRIME_MODULUS);
            end 
           
          else begin
            //$display("input to concrete: %d,%d,%d", mult1_product, galois_add_two(y2_partial[0], mult2_product,PRIME_MODULUS),galois_add_two(y3_partial[0], mult3_product,PRIME_MODULUS));
            concrete_in[0] <= mult1_product;
            concrete_in[1] <= galois_add_two(y2_partial[0], mult2_product,PRIME_MODULUS);
            concrete_in[2] <= galois_add_two(y3_partial[0], mult3_product,PRIME_MODULUS);
          end
        end
        CONCRETE2:begin
                   // $display("concre_out = %d, %d, %d", concrete_out[0], concrete_out[1], concrete_out[2]);
            ct_concrete <= ct_concrete + 1;
            if (ct_concrete == 0) begin
             // $display("input to concrete: %d,%d,%d", inState[0][1],inState[1][1],inState[2][1]);
                concrete_in[0] <= inState[0][1];
                concrete_in[1] <= inState[1][1];
                concrete_in[2] <= inState[2][1];
            end
                        else if (ct_concrete == 4) begin
                //$display("ct_concrete = %1d, input is %d, %d, %d", ct_concrete, add1Sum, add2Sum, add3Sum);
                concrete_in[0] =  galois_add_two(mult1_product, sum1_reg[1], PRIME_MODULUS);
                concrete_in[1] =  galois_add_two(mult2_product, sum2_reg[1], PRIME_MODULUS);
                concrete_in[2] =  galois_add_two(mult3_product, sum3_reg[1], PRIME_MODULUS);
            end 
             else begin
              // $display("input to concrete: %d,%d,%d", mult1_product, galois_add_two(y2_partial[1], mult2_product,PRIME_MODULUS),galois_add_two(y3_partial[1], mult3_product,PRIME_MODULUS));
            concrete_in[0] <= mult1_product;
               concrete_in[1] <= galois_add_two(y2_partial[1], mult2_product,PRIME_MODULUS);
               concrete_in[2] <= galois_add_two(y3_partial[1], mult3_product,PRIME_MODULUS);
          end
        end
        BRICKS1: begin
            /*
                MULT1: mult1_product <- x1^2
                MULT2: mult2_product <- x2^2
                MULT3: mult3_product <- x1*x2
                y2p <- 3*x2
                y3p <- 2*x3
            */
                  //  $display("concre_out = %d, %d, %d", concrete_out[0], concrete_out[1], concrete_out[2]);
          //$display("ct_barrett = %d", ct_barrett);
            ct_barrett <= (ct_barrett == 12)? 0:ct_barrett+1;
            if (ct_concrete == 1) begin
                if (ct_barrett <= 10) begin
                        //        $display("input to concrete: %d,%d,%d", inState[0][ct_barrett+2],inState[1][ct_barrett+2],inState[2][ct_barrett+2]);

                  concrete_in[0] <= inState[0][ct_barrett+2];
                    concrete_in[1] <= inState[1][ct_barrett+2];
                    concrete_in[2] <= inState[2][ct_barrett+2];
                end
            end
            else if (ct_concrete == 5) begin
                if (ct_barrett <= 10) begin
                //$display("ct_concrete = %1d, input is %d, %d, %d", ct_concrete, add1Sum, add2Sum, add3Sum);
                concrete_in[0] =  galois_add_two(mult1_product, sum1_reg[ct_barrett+2], PRIME_MODULUS);
                concrete_in[1] =  galois_add_two(mult2_product, sum2_reg[ct_barrett+2], PRIME_MODULUS);
                concrete_in[2] =  galois_add_two(mult3_product, sum3_reg[ct_barrett+2], PRIME_MODULUS);
                end
            end 
            else begin
              if (ct_barrett <= 10) begin 
              //  $display("input to concrete: %d,%d,%d", mult1_product, galois_add_two(y2_partial[ct_barrett+2], mult2_product,PRIME_MODULUS),galois_add_two(y3_partial[ct_barrett+2], mult3_product,PRIME_MODULUS));
                 concrete_in[0] <= mult1_product;
              concrete_in[1] <= galois_add_two(y2_partial[ct_barrett+2], mult2_product,PRIME_MODULUS);
              concrete_in[2] <= galois_add_two(y3_partial[ct_barrett+2], mult3_product,PRIME_MODULUS);
            end
            end
          //$display("input to BRICK: %d, %d, %d",concrete_out[0], concrete_out[1], concrete_out[2]);
            mult1_num1 <= concrete_out[0];
            mult1_num2 <= concrete_out[0];
            mult2_num1 <= concrete_out[1];
            mult2_num2 <= concrete_out[1];
            mult3_num1 <= concrete_out[0];
            mult3_num2 <= concrete_out[1];
            x1_reg[ct_barrett] <= concrete_out[0];
            x2_reg[ct_barrett] <= concrete_out[1];
            x3_reg[ct_barrett] <= concrete_out[2];
            y3_partial[ct_barrett] <= galois_add_two(concrete_out[2], concrete_out[2], PRIME_MODULUS);
            y2_partial[ct_barrett] <= galois_add_three(concrete_out[1], concrete_out[1], concrete_out[1], PRIME_MODULUS);
        end
        BRICKS2: begin
            /*
                MULT1: mult1_product <- x1^3
                MULT2: mult2_product <- x1^2
                MULT3: mult3_product <- 3*x2*x3
                add3_sum <- x1*x2 + x2
                y2p <- 4*x3
                subsitude x1_reg with x2^2
            */
            ct_barrett <= (ct_barrett==12)?0:ct_barrett+1;
          mult1_num1 <= mult1_product;
            mult1_num2 <= x1_reg[ct_barrett];
            mult2_num1 <= x1_reg[ct_barrett];
            mult2_num2 <= x1_reg[ct_barrett];
            mult3_num1 <= y2_partial[ct_barrett];
            mult3_num2 <= x3_reg[ct_barrett];
          y2_partial[ct_barrett] <= galois_add_two(x2_reg[ct_barrett], mult3_product,PRIME_MODULUS);
            y3_partial[ct_barrett] <= galois_add_three(y3_partial[ct_barrett], x3_reg[ct_barrett], x3_reg[ct_barrett],PRIME_MODULUS);
                      x1_reg[ct_barrett] <= mult2_product;            

        end

        BRICKS3: begin
            /*
                MULT1: mult1_product <- x1^5
                MULT2: mult2_product <- x1^2 * x2
                MULT3: mult3_product <- x2^2 * x3
                add2_sum <- x1*x2 + x2 + x2 (x1*x2 + 2x2)
                add3_sum <- 3x2*x3 + 4*x3
            */
            ct_barrett <= (ct_barrett==12)?0:ct_barrett+1;
            mult1_num1 <= mult1_product;
            mult1_num2 <= mult2_product;
            mult2_num1 <= x2_reg[ct_barrett];
            mult2_num2 <= mult2_product;
            mult3_num1 <= x1_reg[ct_barrett];
            mult3_num2 <= x3_reg[ct_barrett];
            y2_partial[ct_barrett] <= galois_add_two(y2_partial[ct_barrett], x2_reg[ct_barrett], PRIME_MODULUS);
            y3_partial[ct_barrett] <= galois_add_two(mult3_product, y3_partial[ct_barrett], PRIME_MODULUS);
            
        end

        BAR_DECOMP1: begin
            ct_barrett <= (ct_barrett==12)?0:ct_barrett+1;
            if (ct_barrett <= 10) begin
               // $display("input to concrete: %d,%d,%d", mult1_product, galois_add_two(y2_partial[ct_barrett+2], mult2_product,PRIME_MODULUS),galois_add_two(y3_partial[ct_barrett+2], mult3_product,PRIME_MODULUS));
                concrete_in[0] <= mult1_product;
                concrete_in[1] <= galois_add_two(y2_partial[ct_barrett+2], mult2_product,PRIME_MODULUS);
                concrete_in[2] <= galois_add_two(y3_partial[ct_barrett+2], mult3_product,PRIME_MODULUS);
            end
//             $display("BAR_DECOMP1: ct_barrett=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d, s_next=%d, s_lower=%d, x_decompose1=%d, x_decompose2=%d, x_decompose3=%d",
//             ct_barrett, concrete_out[0], LUT_S5_UPPER, concrete_out[1], LUT_S5_UPPER, concrete_out[2], LUT_S5_UPPER, S5, LUT_S5_LOWER, concrete_out[0], concrete_out[1], concrete_out[2]);
        //  $display("BAR_DECOM1: ct_barrett = %d, concrete_out[0] = %d, concrete_out[1] = %d, concrete_out[2] = %d", ct_barrett, concrete_out[0], concrete_out[1], concrete_out[2]);
            mult1_num1 <= concrete_out[0];
            mult1_num2 <= LUT_S5_UPPER;
            mult2_num1 <= concrete_out[1];
            mult2_num2 <= LUT_S5_UPPER;
            mult3_num1 <=concrete_out[2];
            mult3_num2 <= LUT_S5_UPPER;
            s_next <= S5;
            s_lower <= LUT_S5_LOWER;
            x_decompose1 <= concrete_out[0];
            x_decompose2 <= concrete_out[1];
            x_decompose3 <= concrete_out[2];
        end
        BAR_DECOMP2: begin
            ct_barrett <= (ct_barrett==12)?0:ct_barrett+1;
           // $display("BAR_DECOMP2: ct_barrett=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d, s_next=%d, s_lower=%d, x_decompose1=%d, x_decompose2=%d, x_decompose3=%d",
           // ct_barrett, r_reg1, LUT_S4_UPPER, r_reg2, LUT_S4_UPPER, r_reg3, LUT_S4_UPPER, S4, LUT_S4_LOWER, r_reg1, r_reg2, r_reg3);
                mult1_num1 <= r_reg1;
                mult1_num2 <= LUT_S4_UPPER;
                mult2_num1 <= r_reg2;
                mult2_num2 <= LUT_S4_UPPER;
                mult3_num1 <= r_reg3;
                mult3_num2 <= LUT_S4_UPPER;
                s_lower <= LUT_S4_LOWER;
                s_next <= S4;
                x_decompose1 <= r_reg1;
                x_decompose2 <= r_reg2;
                x_decompose3 <= r_reg3;
        end
        BAR_DECOMP3: begin
        //    $display("BAR_DECOMP3: ct_barrett=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d, s_next=%d, s_lower=%d, x_decompose1=%d, x_decompose2=%d, x_decompose3=%d",ct_barrett, r_reg1, LUT_S3_UPPER, r_reg2, LUT_S3_UPPER, r_reg3, LUT_S3_UPPER, S3, LUT_S3_LOWER, r_reg1, r_reg2, r_reg3);

                ct_barrett <= (ct_barrett==12)?0:ct_barrett+1;
                mult1_num1 <= r_reg1;
                mult1_num2 <= LUT_S3_UPPER;
                mult2_num1 <= r_reg2;
                mult2_num2 <= LUT_S3_UPPER;
                mult3_num1 <= r_reg3;
                mult3_num2 <= LUT_S3_UPPER;
                s_lower <= LUT_S3_LOWER;
                s_next <= S3;
                x_decompose1 <= r_reg1;
                x_decompose2 <= r_reg2; 
                x_decompose3 <= r_reg3;
        end

        BAR_DECOMP4: begin
            //    $display("BAR_DECOMP4: ct_barrett=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d, s_next=%d, s_lower=%d, x_decompose1=%d, x_decompose2=%d, x_decompose3=%d",
                  //  ct_barrett, r_reg1, LUT_S2_UPPER, r_reg2, LUT_S2_UPPER, r_reg3, LUT_S2_UPPER, S2, LUT_S2_LOWER, r_reg1, r_reg2, r_reg3);

            ct_barrett <= (ct_barrett==12)?0:ct_barrett + 1;
            mult1_num1 <= r_reg1;
            mult1_num2 <= LUT_S2_UPPER;
            mult2_num1 <= r_reg2;
            mult2_num2 <= LUT_S2_UPPER;
            mult3_num1 <= r_reg3;
            mult3_num2 <= LUT_S2_UPPER;
            s_lower <= LUT_S2_LOWER;
            s_next <= S2;
            x_decompose1 <= r_reg1;
            x_decompose2 <= r_reg2;
            x_decompose3 <= r_reg3;
        end
        BAR_COMP1: begin
            if (ct_barrett==12) begin
                ct_barrett <= 0; 
            end
            else ct_barrett <= ct_barrett + 1;
             
//         $display("BAR_COMP1: ct_barrett=%d, sel=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d",
//             ct_barrett, sel, d1_1, d1_2, d2_1, d2_2, d3_1, d3_2);
        //  $display("BAR_COMP1:ct_barrett = %d, d1_1 = %d, d1_2 = %d, d2_1 = %d, d2_2= %d, d3_1 = %d, d3_2 = %d", ct_barrett, d1_1[ct_barrett], d1_2[ct_barrett], d2_1[ct_barrett], d2_2[ct_barrett], d3_1[ct_barrett], d3_2[ct_barrett]);
            ct_barrett <= (ct_barrett==12)? 0:ct_barrett + 1;
            mult1_num1 <= d1_1[ct_barrett];
            mult1_num2 <= d1_2[ct_barrett];
            mult2_num1 <= d2_1[ct_barrett];
            mult2_num2 <= d2_2[ct_barrett];
            mult3_num1 <= d3_1[ct_barrett];
            mult3_num2 <= d3_2[ct_barrett];
            sum1_reg[ct_barrett] <= d1_5[ct_barrett];
            sum2_reg[ct_barrett] <= d2_5[ct_barrett];
            sum3_reg[ct_barrett] <= d3_5[ct_barrett];
        end
        BAR_COMP2: begin
           //     $display("BAR_COMP2: ct_barrett=%d, sel=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d, COEF_3=%d",
                   // ct_barrett, sel, d1_3[ct_barrett], COEF_3, d2_3[ct_barrett], COEF_3, d3_3[ct_barrett], COEF_3, COEF_3);

            ct_barrett <= (ct_barrett==12)? 0:ct_barrett+1;
            mult1_num1 <= d1_3[ct_barrett];
            mult1_num2 <= COEF_3;
            mult2_num1 <= d2_3[ct_barrett];
            mult2_num2 <= COEF_3;
            mult3_num1 <= d3_3[ct_barrett];
            mult3_num2 <= COEF_3;
            sum1_reg[ct_barrett] <= galois_add_two(composed1, sum1_reg[ct_barrett], PRIME_MODULUS);
            sum2_reg[ct_barrett] <= galois_add_two(composed2, sum2_reg[ct_barrett], PRIME_MODULUS);
            sum3_reg[ct_barrett] <= galois_add_two(composed3, sum3_reg[ct_barrett], PRIME_MODULUS);
        end
        BAR_COMP3: begin
       // $display("BAR_COMP3: ct_barrett=%d, sel=%d, mult1_num1=%d, mult1_num2=%d, mult2_num1=%d, mult2_num2=%d, mult3_num1=%d, mult3_num2=%d, COEF_4=%d",
          //       ct_barrett, sel, d1_4[ct_barrett], COEF_4, d2_4[ct_barrett], COEF_4, d3_4[ct_barrett], COEF_4, COEF_4);
            ct_barrett <= (ct_barrett==12)? 0: ct_barrett + 1;
            mult1_num1 <= d1_4[ct_barrett];
            mult1_num2 <= COEF_4;
            mult2_num1 <= d2_4[ct_barrett];
            mult2_num2 <= COEF_4;
            mult3_num1 <= d3_4[ct_barrett];
            mult3_num2 <= COEF_4;
            sum1_reg[ct_barrett] <= galois_add_two(mult1_product, sum1_reg[ct_barrett], PRIME_MODULUS);
            sum2_reg[ct_barrett] <= galois_add_two(mult2_product, sum2_reg[ct_barrett], PRIME_MODULUS);
            sum3_reg[ct_barrett] <= galois_add_two(mult3_product, sum3_reg[ct_barrett], PRIME_MODULUS);
        end
        DONE: begin
            if (ct_barrett == 12) begin
                done <= 1;
                ct_barrett <= 0;
            end
            else ct_barrett <= ct_barrett + 1;
            if(ct_barrett <= 10) begin
               //  $display("input to concrete: %d,%d,%d", mult1_product, galois_add_two(y2_partial[ct_barrett+2], mult2_product,PRIME_MODULUS),galois_add_two(y3_partial[ct_barrett+2], mult3_product,PRIME_MODULUS));
                 concrete_in[0] <= mult1_product;
              concrete_in[1] <= galois_add_two(y2_partial[ct_barrett+2], mult2_product,PRIME_MODULUS);
              concrete_in[2] <= galois_add_two(y3_partial[ct_barrett+2], mult3_product,PRIME_MODULUS);
            end
            outState[0][ct_barrett] <= concrete_out[0];
            outState[1][ct_barrett] <= concrete_out[1];
            outState[2][ct_barrett] <= concrete_out[2];
        //    $display("ct_barrett = %d", ct_barrett);
          $display("outState[0][%d] = %d",ct_barrett, concrete_out[0]);
          $display("outState[1][%d] = %d", ct_barrett,  concrete_out[1]);
          $display("outState[2][%d] = %d",ct_barrett, concrete_out[2]);
        end
    endcase

end

always_latch begin
    if (state == BAR_DECOMP1) begin 
        d1_5[ct_barrett] = 0;
        d2_5[ct_barrett] = 0;
        d3_5[ct_barrett] = 0;
    end
    if (state == BAR_DECOMP2) begin
        d1_4[ct_barrett] = d1;
        d2_4[ct_barrett] = d2;
        d3_4[ct_barrett] = d3;
    end
    if (state == BAR_DECOMP3) begin
        d1_3[ct_barrett] = d1;
        d2_3[ct_barrett] = d2;
        d3_3[ct_barrett] = d3;
    end
    if (state == BAR_DECOMP4) begin
        d1_2[ct_barrett] = d1;
        d2_2[ct_barrett] = d2;
        d3_2[ct_barrett] = d3;
    end
  if (state == BAR_COMP1) begin
        d1_1[ct_barrett] = d1;
        d2_1[ct_barrett] = d2;
        d3_1[ct_barrett] = d3;
    end 
end

concrete#(.N_BITS(N_BITS), .STATE_SIZE(STATE_SIZE), .PRIME_MODULUS(PRIME_MODULUS)) concrete_instance(
    .inState(concrete_in),
    .round_constants(round_constants),
    .clk(clk),
    .outState(concrete_out)
);
galois_mult_barrett_sync #(
   .N_BITS(N_BITS),
   .BARRETT_R(BARRETT_R),
   .PRIME_MODULUS(PRIME_MODULUS)
) mult_instance1 (
    .sel(sel),
    .clk(clk),
    .num1(mult1_num1),
    .num2(mult1_num2),
    .x_decompse(x_decompose1),
    .s_lower(s_lower),
    .s_next(s_next),
    .product(mult1_product),
    .composed(composed1),
    .d(d1),
    .r_reg(r_reg1)
);
galois_mult_barrett_sync #(
   .N_BITS(N_BITS),
   .BARRETT_R(BARRETT_R),
   .PRIME_MODULUS(PRIME_MODULUS)
) mult_instance2 (
    .sel(sel),
    .clk(clk),
    .num1(mult2_num1),
    .num2(mult2_num2),
    .x_decompse(x_decompose2),
    .s_lower(s_lower),
    .s_next(s_next),
    .product(mult2_product),
    .composed(composed2),
    .d(d2),
    .r_reg(r_reg2)
);
galois_mult_barrett_sync #(
   .N_BITS(N_BITS),
   .BARRETT_R(BARRETT_R),
   .PRIME_MODULUS(PRIME_MODULUS)
) mult_instance3 (
    .sel(sel),
    .clk(clk),
    .num1(mult3_num1),
    .num2(mult3_num2),
    .x_decompse(x_decompose3),
    .s_lower(s_lower),
    .s_next(s_next),
    .product(mult3_product),
    .composed(composed3),
    .d(d3),
    .r_reg(r_reg3)
);

endmodule