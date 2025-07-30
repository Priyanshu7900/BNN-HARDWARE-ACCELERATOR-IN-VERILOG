`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Priyanshu gupta
// Module Name: weight_loader
// Description:
//   Loads encrypted weights from ROM (Model A or B selected).
//   Decrypts them using aes_light_decrypt module.
//   Stores the output weights in RAM (register array).
//   FSM controls the loading/decryption process.
//
//////////////////////////////////////////////////////////////////////////////////

module weight_loader #(
    parameter N = 8,             // Width of each weight
    parameter DEPTH = 16         // Number of weights
)(
    input wire clk,
    input wire rst,
    input wire start,                    // Trigger loading
    input wire [7:0] aes_key,            // Shared symmetric key
    input wire [1:0] active_model,       // 2'b01: Model A, 2'b10: Model B

    // ROM interfaces (dual-model encrypted weights)
    input wire [N-1:0] rom_data_model_a,
    input wire [N-1:0] rom_data_model_b,

    output reg [$clog2(DEPTH)-1:0] rom_addr, // Address to read from both ROMs

    // Output to BNN
    output reg [N-1:0] weight_mem [0:DEPTH-1], // Internal RAM for weights
    output reg done_loading                    // High when all weights loaded
);

    // State encoding
    typedef enum reg [1:0] {
        IDLE = 2'b00,
        LOAD = 2'b01,
        DECRYPT = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t state;

    reg [7:0] decrypt_in;
    wire [7:0] decrypt_out;
    wire decrypt_done;

    reg start_decrypt;
    reg [$clog2(DEPTH)-1:0] count;

    // Select ROM data based on active model
    wire [7:0] rom_data_selected;
    assign rom_data_selected = (active_model == 2'b01) ? rom_data_model_a :
                               (active_model == 2'b10) ? rom_data_model_b : 8'h00;

    // AES-like decryptor
    aes_light_decrypt decryptor (
        .clk(clk),
        .rst(rst),
        .start(start_decrypt),
        .cipher_in(decrypt_in),
        .key(aes_key),
        .plain_out(decrypt_out),
        .done(decrypt_done)
    );

    // FSM: Load and decrypt weights
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rom_addr <= 0;
            done_loading <= 0;
            count <= 0;
            start_decrypt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done_loading <= 0;
                    if (start) begin
                        rom_addr <= 0;
                        count <= 0;
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    decrypt_in <= rom_data_selected; // Use model-specific ROM data
                    start_decrypt <= 1;
                    state <= DECRYPT;
                end

                DECRYPT: begin
                    start_decrypt <= 0;
                    if (decrypt_done) begin
                        weight_mem[count] <= decrypt_out;
                        count <= count + 1;
                        rom_addr <= rom_addr + 1;
                        if (count == DEPTH - 1) begin
                            state <= DONE;
                        end else begin
                            state <= LOAD;
                        end
                    end
                end

                DONE: begin
                    done_loading <= 1;
                    if (!start) begin
                        state <= IDLE;
                        done_loading <= 0;
                    end
                end
            endcase
        end
    end

endmodule
