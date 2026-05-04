`timescale 1ns / 1ps

// ECE 310 - Project 3: Serial BCD ALU
// Ezana Enquobahrie
// Top Level Module: Handles Serial I/O and Sequence Detection

module Project3 (
    input clock,
    input reset,
    input din,
    output result
);

    // --- SIPO and Header Detection ---
    reg [40:0] shift_in;
    reg [32:0] hold_reg; // Stores OP + A + B
    reg start_calc;

    wire [40:0] next_shift = {shift_in[39:0], din};

    always @(posedge clock) begin
        if (reset) begin
            shift_in <= 41'b0;
            hold_reg <= 33'b0;
            start_calc <= 1'b0;
        end else begin
            // Check for control header 8'h67
            if (next_shift[40:33] == 8'h67) begin
                hold_reg <= next_shift[32:0]; 
                start_calc <= 1'b1;
                
                // Clear the shift register entirely. This prevents payload data 
                // from continuously shifting and falsely triggering the header 
                // detector on subsequent clock cycles.
                shift_in <= 41'b0; 
            end else begin
                shift_in <= next_shift;
                start_calc <= 1'b0;
            end
        end
    end

    // --- Instantiate 16-bit BCD ALU ---
    wire op = hold_reg[32]; // 0: Add, 1: Sub
    wire [15:0] A = hold_reg[31:16];
    wire [15:0] B = hold_reg[15:0];
    wire [19:0] alu_result; 

    BCD_ALU my_alu (
        .A(A),
        .B(B),
        .op(op),
        .result(alu_result)
    );

    // --- PISO Output Register ---
    reg [27:0] tx_reg;
    reg [4:0]  tx_count; // Counts down from 28

    always @(posedge clock) begin
        if (reset) begin
            tx_reg <= 28'b0;
            tx_count <= 5'd0;
        end else begin
            if (start_calc) begin
                // Build output packet: 8'hA5 header + 20-bit sum
                tx_reg <= {8'hA5, alu_result};
                tx_count <= 5'd28; 
            end else if (tx_count > 0) begin
                // Shift left to output MSB
                tx_reg <= {tx_reg[26:0], 1'b0};
                tx_count <= tx_count - 1'b1;
            end
        end
    end

    // Output MSB while active, otherwise 0
    assign result = (tx_count > 0) ? tx_reg[27] : 1'b0;

endmodule


// ---------------------------------------------------------
// 16-bit Parallel BCD ALU 
// ---------------------------------------------------------
module BCD_ALU (
    input [15:0] A,
    input [15:0] B,
    input op,
    output [19:0] result
);

    wire c1, c2, c3, final_carry;
    wire [15:0] Sum;

    // Chain 4-bit ALUs. If op=1 (subtraction), Cin of the first digit is 1 
    // to complete the 10's complement conversion.
    bcd_alu_4bit digit0 (A[3:0],   B[3:0],   op, op, Sum[3:0],   c1);
    bcd_alu_4bit digit1 (A[7:4],   B[7:4],   c1, op, Sum[7:4],   c2);
    bcd_alu_4bit digit2 (A[11:8],  B[11:8],  c2, op, Sum[11:8],  c3);
    bcd_alu_4bit digit3 (A[15:12], B[15:12], c3, op, Sum[15:12], final_carry);

    // Discard borrow on subtraction. For addition, carry becomes the 5th digit.
    wire [3:0] digit4 = op ? 4'b0000 : {3'b000, final_carry};

    assign result = {digit4, Sum};

endmodule


// ---------------------------------------------------------
// Single digit 4-bit BCD ALU
// ---------------------------------------------------------
module bcd_alu_4bit(
    input [3:0] A,
    input [3:0] B,
    input Cin,
    input OP,
    output [3:0] Sum,
    output Cout
);

    wire [3:0] B_mod;
    wire [4:0] raw_sum;
    wire adjust;

    // 9's complement of B for subtraction
    assign B_mod = OP ? (4'd9 - B) : B;

    // 5-bit addition
    assign raw_sum = A + B_mod + Cin;

    // Check for invalid BCD range (>9)
    assign adjust = (raw_sum > 9);

    // BCD adjustment: add 6 if > 9 and trigger carry out
    assign Sum = adjust ? (raw_sum + 3'd6) : raw_sum;
    assign Cout = adjust;

endmodule