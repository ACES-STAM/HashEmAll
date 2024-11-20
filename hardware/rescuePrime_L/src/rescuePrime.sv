module rescuePrime #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
  input [N_BITS-1:0] inState[STATE_SIZE][13] ,
    input clk, enable, reset,
    output logic [N_BITS-1:0] outState[STATE_SIZE][13],
    output logic done
);
    localparam MDS_11 = 254'h000000000000000000000000000000000000000000000000000000000000007d;
    localparam MDS_12 = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff66;
    localparam MDS_13 = 254'h000000000000000000000000000000000000000000000000000000000000001f;

    // Row 2
    localparam MDS_21 = 254'h0000000000000000000000000000000000000000000000000000000000000f23;
    localparam MDS_22 = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffedb9;
    localparam MDS_23 = 254'h0000000000000000000000000000000000000000000000000000000000000326;

    // Row 3
    localparam MDS_31 = 254'h000000000000000000000000000000000000000000000000000000000001898e;
    localparam MDS_32 = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effe2722;
    localparam MDS_33 = 254'h0000000000000000000000000000000000000000000000000000000000004f52;
    
    localparam D = 5;
    localparam DINV = 254'h26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd;

    logic [N_BITS-1:0] round_constants[NUM_ROUNDS*2*STATE_SIZE];
    initial begin
        round_constants[0] = 254'h241214b64e37a42dddc49216b6433fe75e4af3533a8c8961def18b459420ce96;
        round_constants[1] = 254'h149e9522e80164b39561a6d532ed480ddb16db399fce8f2b72c8640bed14edd8;
        round_constants[2] = 254'h16e6151eb7f6065df49647b709fcde486776be1e372155e42ce9c91b49342af3;
        round_constants[3] = 254'h0b29463b35fc98ca03baae98f5d4f251d38e091fa179fbe1f10e77e0f46399cd;
        round_constants[4] = 254'h1a892f66364b75798cebe8e3ef3bf830f85ecb833f3b1023f4e90d2fc67a88d9;
        round_constants[5] = 254'h27af8ef16eb7a0535a73aaa4273ea0811b95b6f288e3b18e91ea29857a35f4df;
        round_constants[6] = 254'h03546ef6134d6bcfac31bfdcc211836203a559b0e04b314ff40642b72b1f22b9;
        round_constants[7] = 254'h15392eceb2d870dcedce619bd4a4baf5140dfe1390fcb22d89787f5631f4756d;
        round_constants[8] = 254'h238fa99e483edf2d219d37dcf824e86ed4fc7b384a4fecc8a0f5c8109fa0d0e7;
        round_constants[9] = 254'h00bf1355bb7cfb01c74f7188922e6120a8c24b612471653b59ac1aff07d44f46;
        round_constants[10] = 254'h16af47292baf23e76016f26496f6c73d3c38f4b1791f3b8762f7f15b89acc9a3;
        round_constants[11] = 254'h105a902eafac24043e91c89164e510e1d7d1948c5660b56c7f6f7672dbe60b75;
        round_constants[12] = 254'h0d7bc0cc3063a9d7c2b85c953ac460a79e70b3ac3fef6f7952658a59cce56cce;
        round_constants[13] = 254'h205aa50ee2dc005f22a93fd5070636e20406843871f8eb4bfce2845e060df6c1;
        round_constants[14] = 254'h0115db7f2494ba498f5168807e455811e55f92d6b48117dd75791b94b0d2e42f;
        round_constants[15] = 254'h116ee19eba3b6f6f24d41133d4cc4d6b22d940b45256d7fb55f7a2bbc56fe585;
        round_constants[16] = 254'h1def0328023519e98741d1bf42429a1ddf9853579b3a59424184c12d0137c33c;
        round_constants[17] = 254'h005746d2203f013e44ac7cd2ca4f7025881a574932e81ee15125558032ca2d9b;
        round_constants[18] = 254'h2c7c456a9d460f23f299aa325599598947fb9289a8d9743efa621cea723cfb8b;
        round_constants[19] = 254'h04f971670f113c12f3e59a3bf8c32a9d71526bd9ff1ca7933bcf42f57cbe9142;
        round_constants[20] = 254'h1ba8e88c0c59e257fce11428c76c7d5d35b5a773d6c7da2609869306e43d0959;
        round_constants[21] = 254'h00762d2d87b03a76a8851f6f5a69d3a6078a8be5028f962098da7be06012a7bc;
        round_constants[22] = 254'h23d7c7a4017398ef348dbb6b4d9f531b0757ad6050704bc7641be4492cf3ca0f;
        round_constants[23] = 254'h0a9cccd695ee8ad147aa245d3d7a30cfc0e0ab6072910d02cc00cf978ca0a89e;
        round_constants[24] = 254'h0a0f24024b1fb9b5afd2997d5e3f1793f99e3f0bccb54dadefddd77b7a42a058;
        round_constants[25] = 254'h024e7d70b40332e5e0d5c790f244ce1685c3062776a792d6144385d1031c6a76;
        round_constants[26] = 254'h0f3e9d716963356b6f4d6c59b5ba5ddccbe583b556a5466e6a8f2d444191542b;
        round_constants[27] = 254'h1fb906fad59abc852df6bad6e47237de825ec36ba13efc46f29a4c8dd680bcaa;
        round_constants[28] = 254'h282fe85ec5d4b5bf5ac6dce1e237e078d107b69b35fe263e295b41a707cb9b42;
        round_constants[29] = 254'h0dee9f78d30ebbcabc8dc0ef1bda1e0a665c218fc9e1d6a1446cc9c8a765015a;
        round_constants[30] = 254'h18d28d7bea35db5e6ddacd576186bc4aae4485f623b49fe505a94054ba75ef0e;
        round_constants[31] = 254'h0cc59f4f8d39b3ac4f2567bc56eb2c7e8da5550a0c04818b42fe695f8f285c20;
        round_constants[32] = 254'h1f1ef239cea48c9aaafcb216b0e08e5fd68cbea8eda24235a6f0ce2c85609659;
        round_constants[33] = 254'h19832475410c38053d6b7085501edf215741207e4bc9548afe8b4b179b9fa253;
        round_constants[34] = 254'h28f1800567daedaa3673eaa304d90334d616dcc9b6a093df07fab20251d2f27a;
        round_constants[35] = 254'h293042c65e37a4efb3190692bc75c5470076513c77b87b9d3535c10f1c5ed68f;
        round_constants[36] = 254'h16019c9451b62d42177d2cacd260a15f0de9cdc9ccb26a892bb8d37ac61ce9bf;
        round_constants[37] = 254'h2323a90bb17a61acbca2205486b44b706cc90fcb4e9900d2970f0df02575c553;
        round_constants[38] = 254'h000c38d85cf32503c63b8ac156492b25f550ad2afddfb92c9c31ac4b6603e304;
        round_constants[39] = 254'h2c69e902753e9b71445f40582287929e6379737b578a73b8b6af949d775d880e;
        round_constants[40] = 254'h046305445d6def7ea13e73f364b5bb76a2480fcaf9e806bd21dc414ec11b7e48;
        round_constants[41] = 254'h189b2620678f5309ee12fff3424a7d65b75a2f674d53da1d594266f477afe57f;
        round_constants[42] = 254'h1c9cb3cad66a96d4f9131760344e7093ae4358bac852f6e352ee345e0dcdf684;
        round_constants[43] = 254'h11cb60a422f7ffcf0a8de27dddd490b6fd93606c37dffc6e8aea256c157fae69;
        round_constants[44] = 254'h23ff8be08521aaa5a6ea6c7fd2c7526afca282b354ee7a559099190e072e3ce4;
        round_constants[45] = 254'h0d4ade548e38a7c4a1976be0cf50cac82e37f202e99413930834a5e117b34276;
        round_constants[46] = 254'h14bc69cef73fe0bb617b6d21dd01cd7f635b169a8b975b8562d9d8460c1aade8;
        round_constants[47] = 254'h0db842e9b71b286915efa0de5e03f8a0378b72b7a71f0c2135e79866d3d6f528;
        round_constants[48] = 254'h1ab35e2f964a0c9641ae01e04747e2a686c76da44ce42579c58c38235ad2eb0c;
        round_constants[49] = 254'h18de353617b2891c392d9f3b6386d74a81f5c4468eebfe8c73200114972fe5b1;
        round_constants[50] = 254'h180b471ce6b043a9401cdd596456af7c67b2b800474bf4fc6932e2edbc62cfbf;
        round_constants[51] = 254'h23153ccd41fb458e2f33c20b8ce49b8985836a26bb06c39f0a96d6bbbc0301ba;
        round_constants[52] = 254'h1416013abc7d9b53aef83185611f5617aba83bfdda11dd489d77cd2012e8a8a7;
        round_constants[53] = 254'h220a789dc01b985c3a137384c37d0b5ad86b7f07f6e0224c66fc0798e9f6459c;
        round_constants[54] = 254'h134dc23093822f920d9c9301b363b224d4fe4f977e11e7a1393244cdfc88ce1a;
        round_constants[55] = 254'h0a2b2d1d9cc5de93ea90b33dcdbf156c000b753b60db180823e717d2c49d6910;
        round_constants[56] = 254'h0091ceffd5b51b15c3b608dd743c9a36eb2ffb6ef374011eb5d0ed60f1ff2b49;
        round_constants[57] = 254'h024de554062063c0168c82ddb650ea09b415c7405d5f3b1430f6eeec0ad3fb0d;
        round_constants[58] = 254'h2c450f23635a10c72b8fc7f36750643a42f62453cd501c83c6c90d16d7eefc57;
        round_constants[59] = 254'h2f14c4092eb0a874c85ae64b4d18bba47970ca3da4d422629ceb040e62b14096;
        round_constants[60] = 254'h2e2561cf8692bdcb2136b5038feca8b05e379a4c6ad4d0f5b4b5af8dc94dc1f7;
        round_constants[61] = 254'h17310c87b9b20d078bb4ea19756cd049afb5dec9734e9745dccd521b007258e1;
        round_constants[62] = 254'h0093cb39757463eb403a16afbec58d3fe5bb0db9a0e69b39e23272fe5420b828;
        round_constants[63] = 254'h0b057a4cb37d03a96cdb20c1f9a96eea600fcd17d2479b228fe9e7ea4befd3c6;
        round_constants[64] = 254'h189552e5eb3ac601a687cae3675cd9c2f72b1a41bcaee2835c03152078590107;
        round_constants[65] = 254'h0518b70350baac601b679aca4238937870f9578567ce3696f81bee468fd7024e;
        round_constants[66] = 254'h0bb790131ed126376809f10b87f7efcd21502e65311c2960f54b0a6953446419;
        round_constants[67] = 254'h01957d4149e870b8124d9da7c079dbe78471228feba9d21b755d2b76b74e2d0d;
        round_constants[68] = 254'h049d840bbb1007263ec4103d9c8fefe67581bfd5cedf6a85d2c1b13613d99b87;
        round_constants[69] = 254'h16663bd42a4d96e3b69edcf1a11950b22cee06402894fdf330128952e31dd397;
        round_constants[70] = 254'h25299e3a923fc0c38ec4d2421077c7e547d9cbd7f9fc89d2915de94b188417c4;
        round_constants[71] = 254'h2a238002a34a8c72b397392f399af21e0e0f7fcc05506e6b874dd3f70bba4b3b;
        round_constants[72] = 254'h0dc6f6cc8d865f25ed467bbf95bbd398dff0d10ae52e2a30be6c8e82344b3802;
        round_constants[73] = 254'h2a72d90ddf392777d2a1977eeb51cb50aee2e9e8b7b7d4c94fb141de94b1ed69;
        round_constants[74] = 254'h00160b8013f8d967f070ff7f978763d30f9f50208558cec97a5e3bb4af933a2d;
        round_constants[75] = 254'h12fa0490ff006e46e16e8aaccba07cd2ba266bfff29bc68449e007349a888207;
        round_constants[76] = 254'h23ddf606bb111b9b21afc99904fa6f75fe37fce69a7e1f7fd5e3d1292ba7e7e0;
        round_constants[77] = 254'h29b2ec689b6f2ed0dbf269c777609432b038a431d432de96688047edc088c1a4;
        round_constants[78] = 254'h2061ba6a4ad4076d895e99f6210c642f745e1e0c103d5407dab83cda773b7fc3;
        round_constants[79] = 254'h00e536b883f7c592c1f6d648bdffa05fd559f399a0a415c7620c16ee8583bbd1;
        round_constants[80] = 254'h2d782ff8b4ff168929034808ce0a8b6493d302444e7777d4aff02f55a3b56769;
        round_constants[81] = 254'h2f6ead5d361bfd4e9986132970afcb85b2f4b4538a6f70bbc75e0f0034c8761a;
        round_constants[82] = 254'h2ac8b859e3deff5e0036d4bb0f0393bc9311336ffea5122cf5e380ebb82d3b55;
        round_constants[83] = 254'h0a1e0608a08cdf1baa58db694c6f73b8d6d598ea447dd6bded6fea2470b38d0a;
    end  
    logic [3:0] ct_barrett;
    logic [N_BITS-1:0] mult1_num1, mult1_num2;
    logic [N_BITS-1:0] mult2_num1, mult2_num2;
    logic [N_BITS-1:0] mult3_num1, mult3_num2;
    logic [N_BITS-1:0] mult4_num1, mult4_num2;
    logic [N_BITS-1:0] mult5_num1, mult5_num2;
    logic [N_BITS-1:0] mult6_num1, mult6_num2;
    logic [N_BITS-1:0] mult1_product;
    logic [N_BITS-1:0] mult2_product;
    logic [N_BITS-1:0] mult3_product;
    logic [N_BITS-1:0] mult4_product;
    logic [N_BITS-1:0] mult5_product;
    logic [N_BITS-1:0] mult6_product;
    logic [N_BITS-1:0] y1[13], y2[13], y3[13], x3[13];
    logic [N_BITS-1:0] add1_num1, add1_num2, add1_num3, add1_sum, add2_num1,add2_num2,add2_num3,add2_sum,add3_num1,add3_num2,add3_num3,add3_sum;
    typedef enum logic[2:0] {INIT, S0, S, S_INV0, SINV, AFFINE_1, AFFINE_2, DONE} state_t;
    state_t state, next_state;
    logic mult_flag_d,mult_flag_dinv, s_done, s_inv_done, affine_done;
    logic [N_BITS-1:0] dinv;
    logic [2:0] d;
    logic readState, initial_round;
    logic [3:0] round;
    logic mult_result_ready_reg[13], mult_result_ready;
    logic [N_BITS-1:0] mult1_reg[13], mult3_reg[13], mult5_reg[13];
    
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

    assign mult_flag_d = d & 1'b1;
    assign mult_flag_dinv = dinv & 1'b1;
    assign s_inv_done = (|dinv)? 0:1;
    assign s_done = (|d)?0:1;
    assign mult_result_ready = mult_result_ready_reg[12];
    always_ff @(posedge clk) begin
            mult_result_ready_reg[1] <= mult_result_ready_reg[0];
            mult_result_ready_reg[2] <= mult_result_ready_reg[1];
            mult_result_ready_reg[3] <= mult_result_ready_reg[2];
            mult_result_ready_reg[4] <= mult_result_ready_reg[3];
            mult_result_ready_reg[5] <= mult_result_ready_reg[4];
            mult_result_ready_reg[6] <= mult_result_ready_reg[5];
            mult_result_ready_reg[7] <= mult_result_ready_reg[6];
            mult_result_ready_reg[8] <= mult_result_ready_reg[7];
            mult_result_ready_reg[9] <= mult_result_ready_reg[8];
            mult_result_ready_reg[10] <= mult_result_ready_reg[9];
            mult_result_ready_reg[11] <= mult_result_ready_reg[10];
            mult_result_ready_reg[12] <= mult_result_ready_reg[11];
        end
        
        always_ff@(posedge clk) begin 
            if (reset) state <= INIT;
            else state <= next_state;
        end
        
        always_comb begin
            case(state)
                INIT: next_state = enable? S0:INIT;
                S0: next_state = (ct_barrett == 12)? S:S0;
                S: next_state = s_done? AFFINE_1: S;
                AFFINE_1: next_state = (ct_barrett==13)? AFFINE_2:AFFINE_1;
                //AFFINE_2: next_state = (ct_barrett==12)? S_INV0: AFFINE_2;
                AFFINE_2: begin
                    if (ct_barrett == 12) begin
                        if (round == NUM_ROUNDS) next_state = affine_done?DONE:S_INV0;
                        else next_state = affine_done? S0:S_INV0;
                    end
                    else next_state = AFFINE_2;
                end
                S_INV0: next_state = (ct_barrett==12)?SINV:S_INV0;
                SINV: next_state = s_inv_done? AFFINE_1: SINV;
                DONE: next_state = (ct_barrett==12)? INIT:DONE;
                default: next_state = INIT;
            endcase
        end

        always_ff @( posedge clk ) begin
            case (state)
                INIT: begin
                    done <= 0;
                    d <= D;
                    dinv <= DINV;
                    ct_barrett <= 0;
                    initial_round <= 1;
                    round <= 0;
                end 

                S0: begin
                    affine_done <= 0;
                    if (ct_barrett == 12) begin
                        initial_round <= 0;
                        d <= d>> 1;
                        ct_barrett <= 0;
                        round <= round + 1;
                    end
                    else ct_barrett <= ct_barrett + 1;

                    mult_result_ready_reg[0] <= 1;
                    if(round == 0) begin
                        $display("initial round");
                      mult1_num1 <= 1;
                      mult1_num2 <= inState[0][ct_barrett];
                      mult2_num1 <= inState[0][ct_barrett];
                      mult2_num2 <= inState[0][ct_barrett];

                      mult3_num1 <= 1;
                      mult3_num2 <= inState[1][ct_barrett];
                      mult4_num1 <= inState[1][ct_barrett];
                      mult4_num2 <= inState[1][ct_barrett];

                      mult5_num1 <= 1;
                      mult5_num2 <= inState[2][ct_barrett];
                      mult6_num1 <= inState[2][ct_barrett];
                      mult6_num2 <= inState[2][ct_barrett];
                    end
                  	else begin
                        mult1_num1 <= 1;
                  		mult1_num2 <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);
                        mult2_num1 <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);
                        mult2_num2 <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);

                        mult3_num1 <= 1;
                        mult3_num2 <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);
                        mult4_num1 <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);
                        mult4_num2 <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);

                        mult5_num1 <= 1;
                        mult5_num2 <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                        mult6_num1 <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                        mult6_num2 <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                    end
                end 
                S: begin
                    if (ct_barrett == 12) begin
                        ct_barrett <= 0; 
                        d <= d>>1;
                    end
                    else ct_barrett <= ct_barrett + 1;

                    if (mult_flag_d) begin
                        mult_result_ready_reg[0] <= 1;
                      
                        mult1_num1 <= mult1_reg[ct_barrett];
                        mult1_num2 <= mult2_product;
                        mult3_num1 <= mult3_reg[ct_barrett];
                        mult3_num2 <= mult4_product;
                        mult5_num1 <= mult5_reg[ct_barrett];
                        mult5_num2 <= mult6_product;
                    end
                    else mult_result_ready_reg[0] <= 0;

                    mult2_num1 <= mult2_product;
                    mult2_num2 <= mult2_product;
                    mult4_num1 <= mult4_product;
                    mult4_num2 <= mult4_product;
                    mult6_num1 <= mult6_product;
                    mult6_num2 <= mult6_product;
                end

                AFFINE_1:begin
                    mult_result_ready_reg[0] <= 0;
                    if (ct_barrett == 13) ct_barrett <= 0;
                    else ct_barrett <= ct_barrett + 1;
                    if (ct_barrett > 0) begin
                      $display("AFFINE LAYER, ct_barrett = %d:",ct_barrett);
                      $display("input to affine is %h", mult1_reg[ct_barrett-1]);
                      $display("input to affine is %h", mult3_reg[ct_barrett-1]);
                      $display("input to affine is %h", mult5_reg[ct_barrett-1]);
                      mult1_num1 <= mult1_reg[ct_barrett-1];
                      mult1_num2 <= MDS_11;
                      mult2_num1 <= mult3_reg[ct_barrett-1];
                      mult2_num2 <= MDS_12;

                      mult3_num1 <= mult1_reg[ct_barrett-1];
                      mult3_num2 <= MDS_21;
                      mult4_num1 <= mult3_reg[ct_barrett-1];
                      mult4_num2 <= MDS_22;

                      mult5_num1 <= mult1_reg[ct_barrett-1];
                      mult5_num2 <= MDS_31;
                      mult6_num1 <= mult3_reg[ct_barrett-1];
                      mult6_num2 <= MDS_32;

                      x3[ct_barrett-1] <= mult5_reg[ct_barrett-1];
                    end 
                end

                AFFINE_2: begin
                    if (ct_barrett == 12) begin
                        ct_barrett <= 0;
                        if (!affine_done) dinv <= DINV;
                        else d <= D;
                    end
                    else ct_barrett <= ct_barrett + 1;
                    // $display("ct_barrett = %d", ct_barrett);
                    // $display("m1p is %h", mult1_product);
                    //  $display("m2p is %h", mult2_product);
                    //   $display("m3p is %h", mult3_product);
                    //    $display("m4p is %h", mult4_product);
                    //     $display("m5p is %h", mult5_product);
                    //      $display("m6p is %h", mult6_product);
                    //      $display("x3[%d] = %h", ct_barrett, x3[ct_barrett]);

                    y1[ct_barrett] <= galois_add_three(mult1_product, mult2_product, round_constants[6*(round-1) + affine_done*3], PRIME_MODULUS);
                    y2[ct_barrett] <= galois_add_three(mult3_product, mult4_product, round_constants[6*(round-1) + affine_done*3+1], PRIME_MODULUS);
                    y3[ct_barrett] <= galois_add_three(mult5_product, mult6_product, round_constants[6*(round-1) + affine_done*3+2], PRIME_MODULUS);
                    mult1_num1 <= x3[ct_barrett];
                    mult1_num2 <= MDS_13;
                    mult2_num1 <= x3[ct_barrett];
                    mult2_num2 <= MDS_23;
                    mult3_num1 <= x3[ct_barrett];
                    mult3_num2 <= MDS_33;
                end
                S_INV0 : begin
                    affine_done <= 1;
                    if (ct_barrett == 12) begin
                        ct_barrett <= 0;
                        dinv <= dinv >> 1;
                    end
                    else ct_barrett <= ct_barrett + 1;
                    // outState[0][ct_barrett] <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);
                    // outState[1][ct_barrett] <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);
                    // outState[2][ct_barrett] <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                    // $display("outState[0][%1d] = %h", ct_barrett,galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS) );
                    // $display("outState[1][%1d] = %h", ct_barrett,galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS) );
                    // $display("outState[2][%1d] = %h", ct_barrett,galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS) );
                    mult_result_ready_reg[0] <= 1;
                    mult1_num1 <= 1;
                    mult1_num2 <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);
                    mult2_num1 <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);
                    mult2_num2 <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);

                    mult3_num1 <= 1;
                    mult3_num2 <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);
                    mult4_num1 <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);
                    mult4_num2 <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);

                    mult5_num1 <= 1;
                    mult5_num2 <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                    mult6_num1 <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                    mult6_num2 <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                end
                SINV: begin
                    if (ct_barrett == 12) begin
                        ct_barrett <= 0; 
                        dinv <= dinv >> 1;
                    end
                    else ct_barrett <= ct_barrett + 1;

                    if(mult_flag_dinv) begin
                        mult_result_ready_reg[0] <= 1;
                        mult1_num1 <= mult1_reg[ct_barrett];
                        mult1_num2 <= mult2_product;
                    
                        mult3_num1 <= mult3_reg[ct_barrett];
                        mult3_num2 <= mult4_product;

                        mult5_num1 <= mult5_reg[ct_barrett];
                        mult5_num2 <= mult6_product;
                    end
                    else mult_result_ready_reg[0] <= 0;
                    
                    mult2_num1 <= mult2_product;
                    mult2_num2 <= mult2_product;
                    mult4_num1 <= mult4_product;
                    mult4_num2 <= mult4_product;
                    mult6_num1 <= mult6_product;
                    mult6_num2 <= mult6_product;
                end

                DONE: begin
                    // if (ct_barrett == 13) begin 
                    //     ct_barrett <= 0;
                    //     done <= 1;
                    // end
                    // else ct_barrett <= ct_barrett + 1;
                    // if (ct_barrett > 0) begin
                    //     $display("ct_barrett = %d", ct_barrett);
                    //     outState[0][ct_barrett-1] <= mult1_reg[ct_barrett-1];
                    //     $display("outState[0][%1d] = %h", ct_barrett-1, mult1_reg[ct_barrett-1]);
                    //     outState[1][ct_barrett-1] <= mult3_reg[ct_barrett-1];
                    //     $display("outState[1][%1d] = %h", ct_barrett-1, mult3_reg[ct_barrett-1]);
                    //     outState[2][ct_barrett-1] <= mult5_reg[ct_barrett-1];
                    //     $display("outState[2][%1d] = %h", ct_barrett-1, mult5_reg[ct_barrett-1]);

                    // end
                    if (ct_barrett == 12) begin
                        done <= 1;
                        ct_barrett <= 0;
                    end
                    else ct_barrett <= ct_barrett + 1;
                    outState[0][ct_barrett] <= galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS);
                    outState[1][ct_barrett] <= galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS);
                    outState[2][ct_barrett] <= galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS);
                    $display("outState[0][%1d] = %h", ct_barrett,galois_add_two(y1[ct_barrett], mult1_product, PRIME_MODULUS) );
                    $display("outState[1][%1d] = %h", ct_barrett,galois_add_two(y2[ct_barrett], mult2_product, PRIME_MODULUS) );
                    $display("outState[2][%1d] = %h", ct_barrett,galois_add_two(y3[ct_barrett], mult3_product, PRIME_MODULUS) );
                end
            endcase            
        end
        
        always_latch begin
            if (mult_result_ready) begin
                mult1_reg[ct_barrett] = mult1_product;
                mult3_reg[ct_barrett] = mult3_product;
                mult5_reg[ct_barrett] = mult5_product;
            end
        end
galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult1_instance (
    .num1(mult1_num1),
    .num2(mult1_num2),
    .clk(clk),
    .product(mult1_product)
);

galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult2_instance (
    .num1(mult2_num1),
    .num2(mult2_num2),
    .clk(clk),
    .product(mult2_product)
);

galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult3_instance (
    .num1(mult3_num1),
    .num2(mult3_num2),
    .clk(clk),
    .product(mult3_product)
);

galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult4_instance (
    .num1(mult4_num1),
    .num2(mult4_num2),
    .clk(clk),
    .product(mult4_product)
);

galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult5_instance (
    .num1(mult5_num1),
    .num2(mult5_num2),
    .clk(clk),
    .product(mult5_product)
);

galois_mult_barrett_sync#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R)) mult6_instance (
    .num1(mult6_num1),
    .num2(mult6_num2),
    .clk(clk),
    .product(mult6_product)
);

galois_add_three#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) add1_instance(
    .num1(add1_num1),
    .num2(add1_num2),
    .num3(add1_num3),
    .sum(add1_sum)
);
galois_add_three#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) add2_instance(
    .num1(add2_num1),
    .num2(add2_num2),
    .num3(add2_num3),
    .sum(add2_sum)
);
galois_add_three#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS)) add3_instance(
    .num1(add3_num1),
    .num2(add3_num2),
    .num3(add3_num3),
    .sum(add3_sum)
);

endmodule