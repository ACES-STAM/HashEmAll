
module griffin #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925, // Size: N_BITS + 1
    parameter STATE_SIZE = 3,
    parameter NUM_ROUNDS = 14
) (
    input clk, reset, enable,
    input [N_BITS-1:0] inState[STATE_SIZE][13],
    output logic [N_BITS-1:0] outState[STATE_SIZE][13],
    output logic done
);

  logic [N_BITS-1:0] ROUND_CONSTANTS [45];
  initial begin
    ROUND_CONSTANTS[0] = 0;
    ROUND_CONSTANTS[1] = 0;
    ROUND_CONSTANTS[2] = 0;
    ROUND_CONSTANTS[0+3]  = 254'h2fb30cafdb1f76156dfabf0cd0af4b895e764ac2a84386c9d0d7aed6a7f4eac9;
    ROUND_CONSTANTS[1+3]  = 254'h282927892ce324572f19abb14871d2b539a80d8a5800cdb87a81e1697a94b6c9;
    ROUND_CONSTANTS[2+3]  = 254'h03d0f3f2711dd59e3d97fc797261300cd3fee33b95cf710a32edf42aa2bc0905;
    ROUND_CONSTANTS[3+3]  = 254'h036a8b3eb9ef35c74ea5a367ed279ee6d043d4ff69817f192c7251b91dcbb03d;
    ROUND_CONSTANTS[4+3]  = 254'h2a626d396e7fa8ce8d6339bb37bd48491d56db0c7ac0afb5008a7464d5776a26;
    ROUND_CONSTANTS[5+3]  = 254'h0cc9dfabbeaef7982543453ea3ac37ef2bfefd35a7e7070aa39b021035852d5b;
    ROUND_CONSTANTS[6+3]  = 254'h2a1951149e2568ab28e972a2ceddc49eff0cae8e1cddcf4b0684a73a1b4ef61b;
    ROUND_CONSTANTS[7+3]  = 254'h2d0ff8e9158b2fd7ae3afe01cf09d4ce9ff81e6127e441eb6cbc79d21f22be9e;
    ROUND_CONSTANTS[8+3]  = 254'h1cc315b7ea0c1efb538f0c3248a7da062309a9e41af5a555c9ea9e8a10930cb5;
    ROUND_CONSTANTS[9+3]  = 254'h03cb10093ea62fb3f6e5680a128d07112ee566f1b424558f2ec9d86892e13a80;
    ROUND_CONSTANTS[10+3] = 254'h12e7bb50ae7e9e90f1765c073eb61c4be4956c424930233ce497d2722a458868;
    ROUND_CONSTANTS[11+3] = 254'h006b1367547937ae71e2e9b55d2f90c90131f9e6784ce3de0eb314ec748871e7;
    ROUND_CONSTANTS[12+3] = 254'h1ffff572c53442c58809aeca02287839b11df1420deb0e99fde2baad8b86fa9c;
    ROUND_CONSTANTS[13+3] = 254'h13aefd685e7739f9a8b4ccdbfc5ef9e566149af4d54d6b746058ea44cb422840;
    ROUND_CONSTANTS[14+3] = 254'h1ea6c3ea93fe6f4ed0186941650de76ff94ab0e6e8a583996b67ba026dd2b7a5;
    ROUND_CONSTANTS[15+3] = 254'h288f120288f9225643de833c5c15e22aadd358132bbdc12c75109048a158c9f4;
    ROUND_CONSTANTS[16+3] = 254'h0f638114cd7c781ab299e5233338b00cf2996df962347a00146a22103d9ad91a;
    ROUND_CONSTANTS[17+3] = 254'h14eeca5fa2c18999ea25ddf44237d6ac3cb8757ea452f67e2590a46f7d5b1e4f;
    ROUND_CONSTANTS[18+3] = 254'h102d1a099e8cd107dc056e72370e340b0316d237b72d99ef6261761f7eb2d61c;
    ROUND_CONSTANTS[19+3] = 254'h0ef741fc2fcda50f207c759dbd844a4d630cc0e4062ca80f3ffba2cce2d3f51d;
    ROUND_CONSTANTS[20+3] = 254'h0989b9f642485692a1f91a4b207db64f38ae545bf3e0622f3862967d27f563db;
    ROUND_CONSTANTS[21+3] = 254'h1eb4d812c80ce04784a80c89fbcc5aab89db274c62602bdd30f3223655e6cf8a;
    ROUND_CONSTANTS[22+3] = 254'h0124a9400253731facd46e21f41016aed69a79087f81665bc5d29a34e4e924dd;
    ROUND_CONSTANTS[23+3] = 254'h2520bfa6b70e6ba7ad380aaf9015b71983868a9c53e66e685ed6e48692c185a8;
    ROUND_CONSTANTS[24+3] = 254'h1bd62b5bfa02667ac08d51d9e77bb3ab8dbd19e7a701442a20e23f7d3d6b28b4;
    ROUND_CONSTANTS[25+3] = 254'h1ae2f0d09fffc6bb869ebc639484a7c2084cfa3c1f88a7440713b1b154e5f952;
    ROUND_CONSTANTS[26+3] = 254'h0cd06e16a0d570c3799d800d92a25efbd44a795ed5b9114a28f5f869a57d9ba1;
    ROUND_CONSTANTS[27+3] = 254'h00691740e313922521fe8c4843355eff8de0f93d4f62df0fe48755b897881c39;
    ROUND_CONSTANTS[28+3] = 254'h19903aa449fe9c27ee9c8320e6915b50c2822e61ce894be72b47a449c5705762;
    ROUND_CONSTANTS[29+3] = 254'h126e801aae44016a35deceaa3eba6ccc341fa3c2a65ab3d021fcd39abd170e1b;
    ROUND_CONSTANTS[30+3] = 254'h1b0a98be27b54ac9d5d72b94187c991c1872cb2c7777c0e880f439c133971e8d;
    ROUND_CONSTANTS[31+3] = 254'h1e10a35afda2e5a173d4f3edecf29dacf51d8fac33d6bfb4088cc787ec647605;
    ROUND_CONSTANTS[32+3] = 254'h1793cda85abe2782ea8e911ce92bab59a8c68e0dd561a57b064bb233f109cc57;
    ROUND_CONSTANTS[33+3] = 254'h146ecffb34a66316fae66609f78d1310bc14ad7208082ca7943afebb1da4aa4a;
    ROUND_CONSTANTS[34+3] = 254'h2b568115d544c7e941eff6ccc935384619b0fb7d2c5ba6c078c34cf81697ee1c;
    ROUND_CONSTANTS[35+3] = 254'h03d9106689dfb2b72dba6618714ce913784df9ac78566ca0ff777e14e954c043;
    ROUND_CONSTANTS[36+3] = 254'h10024c68248583de0c31b52540f3142b6da22422932c9f73b29aa011b87a8e02;
    ROUND_CONSTANTS[37+3] = 254'h164195f933816eeafd0e795c6ead80cee71e009462535bd91bf2a2a2d6f1f62c;
    ROUND_CONSTANTS[38+3] = 254'h0f28cdd300f6f00089a2f5dafc4d485339e897ba8c5c9aa51fac37889f2b380a;
    ROUND_CONSTANTS[42] = 0;
    ROUND_CONSTANTS[43] = 0;
    ROUND_CONSTANTS[44] = 0;
end

  typedef enum logic[2:0] {INIT,AFFINE1,AFFINE2, NONLINEAR, DONE  } state_t;
  state_t state, next_state;
  logic [3:0] round;
  logic affine_done;
  logic [N_BITS-1:0] affine_in[STATE_SIZE], affine_out[STATE_SIZE];
  logic [N_BITS-1:0] nonlinear_in[STATE_SIZE][13], nonlinear_out[STATE_SIZE][13];
  logic nonlinear_enable, nonlinear_done;
  logic [N_BITS-1:0] round_constants[STATE_SIZE];
  logic [5:0] round_idx;
  logic initial_affine;
  logic [3:0] ct_barrett;
  assign round_constants[0] = ROUND_CONSTANTS[round_idx];
  assign round_constants[1] = ROUND_CONSTANTS[round_idx+1];
  assign round_constants[2] = ROUND_CONSTANTS[round_idx+2];
  assign round_idx = 3*round;
  always_ff@( posedge clk ) begin
    if (reset) state <= INIT;
    else state <= next_state;
  end
  
  always_comb begin
    case (state)
      INIT: next_state = enable? AFFINE1:INIT;
      AFFINE1: next_state = AFFINE2;
      AFFINE2: begin
        if (round == 14) next_state = DONE;
        else next_state = NONLINEAR;
      end
      NONLINEAR: begin
        next_state = nonlinear_done? AFFINE1:NONLINEAR;
      end
      DONE: next_state = (ct_barrett==12)? INIT: DONE;
      default: next_state = INIT; 
    endcase
  end

  always_ff @( posedge clk ) begin
    case (state)
      INIT: begin
        initial_affine <= 1;
        nonlinear_enable <= 0; 
        done <= 0;
        ct_barrett <= 0;
        round <= 0;
        affine_done <= 0;
      end 
      AFFINE1: begin
        ct_barrett <= 0;
        if(initial_affine) begin

          for(int i = 0; i < STATE_SIZE; i++) affine_in[i] <= inState[i][0];
        end 
        else for(int i = 0; i < STATE_SIZE; i++) affine_in[i] <= nonlinear_out[i][0];
      end
      AFFINE2: begin
        if(initial_affine) begin
          for(int i = 0; i < STATE_SIZE; i++) affine_in[i] <= inState[i][1];
        end 
        else for(int i = 0; i < STATE_SIZE; i++) affine_in[i] <= nonlinear_out[i][1];      
      end
      NONLINEAR: begin
       	
        if (ct_barrett < 13) begin
          for (int i = 0;i<STATE_SIZE ;i++ ) nonlinear_in[i][ct_barrett] <= affine_out[i];
          ct_barrett <= ct_barrett + 1;
          nonlinear_enable <= 1;
        end
        
        else nonlinear_enable <= 0;
        
        if (ct_barrett <= 10) begin
          if (initial_affine) begin
            for(int i = 0; i < STATE_SIZE; i++) affine_in[i] <= inState[i][ct_barrett+2];
          end
           else begin
            for(int i = 0; i < STATE_SIZE; i++) affine_in[i] <= nonlinear_out[i][ct_barrett+2];
           end
        end
        if (nonlinear_done) begin
          initial_affine <= 0;
          round <= round + 1;
        end
        
      end
      DONE: begin
        ct_barrett <= (ct_barrett==12)? 0:ct_barrett+1;
        if(ct_barrett==12) done <= 1;
        if (ct_barrett <= 10) begin
          affine_in[0] <= nonlinear_out[0][ct_barrett+2];
          affine_in[1] <= nonlinear_out[1][ct_barrett+2];
          affine_in[2] <= nonlinear_out[2][ct_barrett+2];
        end
        for (int i=0; i<STATE_SIZE;i++ ) begin
          outState[i][ct_barrett] <= affine_out[i];
          $display("outState[%1d][%2d] = %h", i, ct_barrett, affine_out[i]);
        end
      end
    endcase
  end

  nonlinear#(.N_BITS(N_BITS), .PRIME_MODULUS(PRIME_MODULUS), .BARRETT_R(BARRETT_R), .STATE_SIZE(STATE_SIZE)) nonlinear_inst (
    .clk(clk),
    .enable(nonlinear_enable),
    .reset(reset),
    .done(nonlinear_done),
    .inState(nonlinear_in),
    .outState(nonlinear_out)
  );

  affine_3#(.N_BITS(N_BITS), .STATE_SIZE(STATE_SIZE), .PRIME_MODULUS(PRIME_MODULUS)) affine_inst(
    .inState(affine_in),
    .clk(clk),
    .round_constants(round_constants),
    .outState(affine_out)
  );
endmodule