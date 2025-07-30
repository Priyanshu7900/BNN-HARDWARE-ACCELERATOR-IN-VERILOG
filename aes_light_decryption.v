//////////////////////////////////////////////////////////////////////////////////
// Company:  Sparkonics Hackathon
// Engineer: Priyanshu Gupta
// 
// Module Name: aes_light_decrypt
// Description: 
//   Simplified AES-like decryptor for use in Secure BNN accelerator.
//   Works on 8-bit input blocks with a 2-round decryption scheme.
//   Components:
//     - SubBytes (S-box)
//     - ShiftRows (bit rearrangement)
//     - AddRoundKey (XOR key)
//
//////////////////////////////////////////////////////////////////////////////////
module aes_light_decrypt(
    input wire clk,
    input wire rst,
    input wire start,                   // Trigger decryption
    input wire [7:0] cipher_in,         // Encrypted input (1 byte)
    input wire [7:0] key,               // Symmetric key (1 byte)
    output reg [7:0] plain_out,         // Decrypted output
    output reg done                     // High when decryption is done
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        ROUND1 = 2'b01,
        ROUND2 = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t state;

    // Internal registers
    reg [7:0] state_reg;   // Working byte
    reg [7:0] round_key1, round_key2;

    // S-Box for SubBytes operation (inverted AES mini S-box)
    function [7:0] sub_byte;
        input [7:0] in;
        begin
            case (in)
                8'h00: sub_byte = 8'h63;
                8'h01: sub_byte = 8'h7c;
                8'h02: sub_byte = 8'h77;
                8'h03: sub_byte = 8'h7b;
                8'h04: sub_byte = 8'hf2;
                8'h05: sub_byte = 8'h6b;
                8'h06: sub_byte = 8'h6f;
                8'h07: sub_byte = 8'hc5;
                default: sub_byte = in ^ 8'h1F; // simplified fallback
            endcase
        end
    endfunction

    // ShiftRows: Bit permutation (simple for 8-bit)
    function [7:0] shift_rows;
        input [7:0] in;
        begin
            // Rotate left by 2 bits
            shift_rows = {in[5:0], in[7:6]};
        end
    endfunction

    // FSM logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            plain_out <= 0;
            done <= 0;
            state_reg <= 0;
            round_key1 <= 0;
            round_key2 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state_reg <= cipher_in ^ key; // Initial AddRoundKey
                        round_key1 <= key ^ 8'h55;
                        round_key2 <= key ^ 8'hAA;
                        state <= ROUND1;
                    end
                end

                ROUND1: begin
                    state_reg <= sub_byte(state_reg);
                    state_reg <= shift_rows(state_reg);
                    state_reg <= state_reg ^ round_key1;
                    state <= ROUND2;
                end

                ROUND2: begin
                    state_reg <= sub_byte(state_reg);
                    state_reg <= shift_rows(state_reg);
                    state_reg <= state_reg ^ round_key2;
                    plain_out <= state_reg;
                    done <= 1;
                    state <= DONE;
                end

                DONE: begin
                    if (!start) begin
                        done <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
