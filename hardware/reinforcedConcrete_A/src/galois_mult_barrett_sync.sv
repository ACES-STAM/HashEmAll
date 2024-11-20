module galois_mult_barrett_sync #(
    parameter N_BITS = 254,
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001, // Size: N_BITS
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925 // Size: N_BITS + 1
) (
    input [1:0] sel,
    input clk,
  input  [256-1:0] num1,
  input  [256-1:0] num2,
    input [N_BITS-1:0] x_decompse,
    input [189:0] s_lower,
    input [66:0] s_next,
    output [N_BITS-1:0] product,
    output logic [198:0] composed,
    output [69:0] d,
    output logic [191:0] r_reg
);

localparam MULT_LATENCY = 3+1; // Clock cylces
localparam COEF_1 = 67'h55aa54d38e5267eea; // S2
localparam COEF_2 = 130'h341ed305184112971d2cc9994e70da0b8; // S2*S3
reg [N_BITS-1:0] result;
reg [256-1:0] mult_1_num1;
reg [256-1:0] mult_1_num2;
reg [256-1:0] mult_2_num1;
reg [256-1:0] mult_2_num2;
reg [256-1:0] mult_3_num1;
reg [256-1:0] mult_3_num2;
reg [N_BITS:0] w_saved [0:(2*MULT_LATENCY)-1];
reg [(2*N_BITS)-1:0] w;
reg [2*(N_BITS+1)-1:0] y;
reg [(2*N_BITS)-1:0] z;

wire [(N_BITS+1)-1:0] x;
wire signed [(N_BITS+1+1)-1:0] x1;
wire signed [(N_BITS+1+1)-1:0] x2;
wire [2*256-1:0] mult_1_product;
wire [2*256-1:0] mult_2_product;
wire [2*256-1:0] mult_3_product;
logic [2*256-1:0] mult_3_product_reg;
logic [N_BITS-1:0] mult_product;
logic [198:0] compose_result;
integer i;
logic [66:0] num2_delayed[4];
logic [133:0] composed_1_saved, composed_1_saved0, composed_1_saved1, composed_1_saved2, composed_1_saved3;
logic [197:0] composed_2;
logic [2*256-1:0] partial_hi[MULT_LATENCY];
logic [66:0] s_lo[MULT_LATENCY];
logic[N_BITS-1:0] x_reg0, x_reg1, x_reg2, x_reg3, x_reg4, x_reg5, x_reg6, x_reg7, x_reg8, x_reg9, x_reg10, x_reg11;
logic [66:0] s_next_reg[2*MULT_LATENCY];
logic [700:0] r;
logic [191:0] r_shifted;
logic [191:0] r_shifted_delayed0, r_shifted_delayed1, r_shifted_delayed2;
logic [1:0] sel_reg0;
logic [1:0] sel_reg1;
logic [1:0] sel_reg2;
logic [1:0] sel_reg3;
logic [1:0] sel_reg4;
logic [1:0] sel_reg5;
logic [1:0] sel_reg6;
logic [1:0] sel_reg7;
logic [1:0] sel_reg8;
logic [1:0] sel_reg9;
logic [1:0] sel_reg10;
logic [1:0] sel_reg11;
logic [1:0] sel_reg12;
always_ff @( posedge clk ) begin : blockName
    if (sel_reg0 == 0) begin
        mult_1_num1 <= num1;
        mult_1_num2 <= num2;
    end
    else if (sel_reg0 == 1) begin
        mult_1_num1 <= num1;
        mult_1_num2 <= COEF_1;
    end
    else if (sel_reg0 == 2) begin
        mult_1_num1 <= num1;
        mult_1_num2 <= num2;
    end
end

always_ff @( posedge clk ) begin
    if (sel_reg4 == 0) begin
        mult_2_num1 <= {1'b0, w[2*N_BITS-1:N_BITS-1]};
        mult_2_num2 <= {1'b0, BARRETT_R};
    end 
    else if (sel_reg4 == 1) begin
        mult_2_num1 <= num2_delayed[3];
        mult_2_num2 <= COEF_2;
    end
    else if (sel_reg4 == 2) begin
        mult_2_num1 <= x_reg3;
        mult_2_num2 <= s_lo[3];
    end
end
always_ff @( posedge clk ) begin
    if (sel_reg8 == 0) begin
        mult_3_num1 <= {2'b0, y[2*N_BITS:N_BITS+1]};
        mult_3_num2 <= {2'b0, PRIME_MODULUS};   
    end
    else if (sel_reg8==1) begin
        mult_3_num1 <= compose_result;
        //$display("mult3_num1 is %h", compose_result);
        mult_3_num2 <= 1;
    end
    else if (sel_reg8 == 2) begin
        mult_3_num1 <= r_shifted;
        mult_3_num2 <= s_next_reg[7];
    end
end

always_ff @( posedge clk ) begin 
    y <= mult_2_product[2*(N_BITS+1)-1:0];
    num2_delayed[0] <= num2;
    for (int i = 1; i < MULT_LATENCY; i++) num2_delayed[i] <= num2_delayed[i-1];
    w <= mult_1_product;
    w_saved[0] <= w[N_BITS:0];
    for (int i = 1; i < 2*MULT_LATENCY; i++) w_saved[i] <= w_saved[i-1];
    
    z <= mult_3_product[2*N_BITS-1:0];
    composed_1_saved <= mult_1_product;
	composed_1_saved0 <= composed_1_saved;
    composed_1_saved1 <= composed_1_saved0;
    composed_1_saved2 <= composed_1_saved1;
    composed_1_saved3 <= composed_1_saved2;
    composed_2 <= mult_2_product;  

    composed <= mult_3_product;
    partial_hi[0] <= mult_1_product;
    for (int i = 1; i < MULT_LATENCY; i++)begin
        s_lo[i] <= s_lo[i-1];
        partial_hi[i] <= partial_hi[i-1];
    end 
    for (int i = 1; i < 2*MULT_LATENCY; i++) s_next_reg[i] <= s_next_reg[i-1];
    x_reg1 <= x_reg0;
    x_reg2 <= x_reg1;
    x_reg3 <= x_reg2;
    x_reg4 <= x_reg3;
    x_reg5 <= x_reg4;
    x_reg6 <= x_reg5;
    x_reg7 <= x_reg6;
    x_reg8 <= x_reg7;
    x_reg9 <= x_reg8;
    x_reg10 <= x_reg9;
    x_reg11 <= x_reg10;
    s_lo[0] <= s_lower;
    x_reg0 <= x_decompse;
    s_next_reg[0] <= s_next;
    r <= (partial_hi[3] << 190) + mult_2_product;
    
    r_shifted_delayed0 <= r_shifted;
    r_shifted_delayed1 <= r_shifted_delayed0;
    r_shifted_delayed2 <= r_shifted_delayed1;
    r_reg <= r_shifted_delayed2;
    sel_reg0 <= sel;
    sel_reg1 <= sel_reg0;
    sel_reg2 <= sel_reg1;
    sel_reg3 <= sel_reg2;
    sel_reg4 <= sel_reg3;
    sel_reg5 <= sel_reg4;
    sel_reg6 <= sel_reg5;
    sel_reg7 <= sel_reg6;
    sel_reg8 <= sel_reg7;
    sel_reg9 <= sel_reg8;
    sel_reg10 <= sel_reg9;
    sel_reg11 <= sel_reg10;
    sel_reg12 <= sel_reg11;
    mult_3_product_reg <= mult_3_product;
end

assign r_shifted = r >> 508;
assign x = w_saved[(2*MULT_LATENCY)-1][(N_BITS+1)-1:0] - z[(N_BITS+1)-1:0];
assign x1 = x - PRIME_MODULUS;
assign x2 = x - 2*PRIME_MODULUS;
assign mult_product = x2 >= 0 ? x2[N_BITS-1:0] : x1 >= 0 ? x1[N_BITS-1:0] : x[N_BITS-1:0];
assign compose_result = composed_1_saved3 + composed_2;
assign product = mult_product; 
assign d = ((x_reg11 - mult_3_product_reg) >0)? x_reg11 - mult_3_product_reg:0;  
mult_256_sync MULT_1 (
    .clk(clk),
    .num1(mult_1_num1),
    .num2(mult_1_num2),
    .product(mult_1_product)
);

mult_256_sync MULT_2 (
    .clk(clk),
    .num1(mult_2_num1),
    .num2(mult_2_num2),
    .product(mult_2_product)
);

mult_256_sync MULT_3 (
    .clk(clk),
    .num1(mult_3_num1),
    .num2(mult_3_num2),
    .product(mult_3_product)
);

endmodule