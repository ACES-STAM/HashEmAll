module galois_mult_254#(
     parameter N_BITS = 254,
     parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
) (
    input clk,
    input [4:0] num1,    // num1 is a 5-bit number (maximum value is 23)
    input [N_BITS-1:0] num2,  // num2 is 254 bits
    output [N_BITS-1:0] result // The product is at most 259 bits wide
);
localparam [258:0] PRIME_MODULUS_2 = PRIME_MODULUS * 2;
localparam [258:0] PRIME_MODULUS_3 = PRIME_MODULUS * 3;
localparam [258:0] PRIME_MODULUS_4 = PRIME_MODULUS * 4;
localparam [258:0] PRIME_MODULUS_5 = PRIME_MODULUS * 5;
localparam [258:0] PRIME_MODULUS_6 = PRIME_MODULUS * 6;
localparam [258:0] PRIME_MODULUS_7 = PRIME_MODULUS * 7;
localparam [258:0] PRIME_MODULUS_8 = PRIME_MODULUS * 8;
localparam [258:0] PRIME_MODULUS_9 = PRIME_MODULUS * 9;
localparam [258:0] PRIME_MODULUS_10 = PRIME_MODULUS * 10;
localparam [258:0] PRIME_MODULUS_11 = PRIME_MODULUS * 11;
localparam [258:0] PRIME_MODULUS_12 = PRIME_MODULUS * 12;
localparam [258:0] PRIME_MODULUS_13 = PRIME_MODULUS * 13;
localparam [258:0] PRIME_MODULUS_14 = PRIME_MODULUS * 14;
localparam [258:0] PRIME_MODULUS_15 = PRIME_MODULUS * 15;
localparam [258:0] PRIME_MODULUS_16 = PRIME_MODULUS * 16;
localparam [258:0] PRIME_MODULUS_17 = PRIME_MODULUS * 17;
localparam [258:0] PRIME_MODULUS_18 = PRIME_MODULUS * 18;
localparam [258:0] PRIME_MODULUS_19 = PRIME_MODULUS * 19;
localparam [258:0] PRIME_MODULUS_20 = PRIME_MODULUS * 20;
localparam [258:0] PRIME_MODULUS_21 = PRIME_MODULUS * 21;
localparam [258:0] PRIME_MODULUS_22 = PRIME_MODULUS * 22;

reg [31:0] partial_product_lo [0:9];  // Each partial product is 32 bits (5+27)
reg [258:0] sum_tree_lo_reg [0:10];   // Registers to store sum tree results
logic [258:0] product;
logic [258:0] result_reg;

// Stage 1: Perform multiplications (multiplication happens in one cycle)
always @(posedge clk) begin
    // 9 complete 27-bit chunks and 1 partial chunk of 11 bits
    partial_product_lo[0] <= num1 * num2[26:0];         // bits 0-26
    partial_product_lo[1] <= num1 * num2[53:27];        // bits 27-53
    partial_product_lo[2] <= num1 * num2[80:54];        // bits 54-80
    partial_product_lo[3] <= num1 * num2[107:81];       // bits 81-107
    partial_product_lo[4] <= num1 * num2[134:108];      // bits 108-134
    partial_product_lo[5] <= num1 * num2[161:135];      // bits 135-161
    partial_product_lo[6] <= num1 * num2[188:162];      // bits 162-188
    partial_product_lo[7] <= num1 * num2[215:189];      // bits 189-215
    partial_product_lo[8] <= num1 * num2[242:216];      // bits 216-242
    partial_product_lo[9] <= num1 * num2[253:243];      // bits 243-253 (11 bits)
end

// Stage 2: Perform additions using a sum tree (addition happens in another cycle)
always @(posedge clk) begin
    // First level: Pair adjacent partial products with proper shifts
    sum_tree_lo_reg[6] <= partial_product_lo[0] + (partial_product_lo[1] << 27);
    sum_tree_lo_reg[7] <= partial_product_lo[2] + (partial_product_lo[3] << 27);
    sum_tree_lo_reg[8] <= partial_product_lo[4] + (partial_product_lo[5] << 27);
    sum_tree_lo_reg[9] <= partial_product_lo[6] + (partial_product_lo[7] << 27);
    sum_tree_lo_reg[10] <= partial_product_lo[8] + (partial_product_lo[9] << 27);

    // Second level: Combine pairs from first level
    sum_tree_lo_reg[3] <= sum_tree_lo_reg[6] + (sum_tree_lo_reg[7] << 54);
    sum_tree_lo_reg[4] <= sum_tree_lo_reg[8] + (sum_tree_lo_reg[9] << 54);
    sum_tree_lo_reg[5] <= sum_tree_lo_reg[10];

    // Third level: Final combinations
    sum_tree_lo_reg[1] <= sum_tree_lo_reg[3] + (sum_tree_lo_reg[4] << 108);
    sum_tree_lo_reg[2] <= sum_tree_lo_reg[5];

    // Final sum
    product <= sum_tree_lo_reg[1] + (sum_tree_lo_reg[2] << 216);
end

always_comb begin
    if (product >= PRIME_MODULUS_22) result_reg = product - PRIME_MODULUS_22;
    else if (product >= PRIME_MODULUS_21) result_reg = product - PRIME_MODULUS_21;
    else if (product >= PRIME_MODULUS_20) result_reg = product - PRIME_MODULUS_20;
    else if (product >= PRIME_MODULUS_19) result_reg = product - PRIME_MODULUS_19;
    else if (product >= PRIME_MODULUS_18) result_reg = product - PRIME_MODULUS_18;
    else if (product >= PRIME_MODULUS_17) result_reg = product - PRIME_MODULUS_17;
    else if (product >= PRIME_MODULUS_16) result_reg = product - PRIME_MODULUS_16;
    else if (product >= PRIME_MODULUS_15) result_reg = product - PRIME_MODULUS_15;
    else if (product >= PRIME_MODULUS_14) result_reg = product - PRIME_MODULUS_14;
    else if (product >= PRIME_MODULUS_13) result_reg = product - PRIME_MODULUS_13;
    else if (product >= PRIME_MODULUS_12) result_reg = product - PRIME_MODULUS_12;
    else if (product >= PRIME_MODULUS_11) result_reg = product - PRIME_MODULUS_11;
    else if (product >= PRIME_MODULUS_10) result_reg = product - PRIME_MODULUS_10;
    else if (product >= PRIME_MODULUS_9) result_reg = product - PRIME_MODULUS_9;
    else if (product >= PRIME_MODULUS_8) result_reg = product - PRIME_MODULUS_8;
    else if (product >= PRIME_MODULUS_7) result_reg = product - PRIME_MODULUS_7;
    else if (product >= PRIME_MODULUS_6) result_reg = product - PRIME_MODULUS_6;
    else if (product >= PRIME_MODULUS_5) result_reg = product - PRIME_MODULUS_5;
    else if (product >= PRIME_MODULUS_4) result_reg = product - PRIME_MODULUS_4;
    else if (product >= PRIME_MODULUS_3) result_reg = product - PRIME_MODULUS_3;
    else if (product >= PRIME_MODULUS_2) result_reg = product - PRIME_MODULUS_2;
    else if (product >= PRIME_MODULUS) result_reg = product - PRIME_MODULUS;
  	else if (product < PRIME_MODULUS) result_reg = product;

end

assign result = result_reg[253:0];
endmodule