
module memory_blocks #(
    parameter N = 8,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [1:0] active_model, // <=== NEW: from config_interface

    input wire [$clog2(DEPTH)-1:0] rom_addr,
    output reg [N-1:0] rom_data,

    input wire [$clog2(DEPTH)-1:0] ram_addr,
    input wire [N-1:0] ram_din,
    input wire ram_write_en,
    output reg [N-1:0] ram_dout
);

    // ROMs for model A and B
    reg [N-1:0] rom_model_a [0:DEPTH-1];
    reg [N-1:0] rom_model_b [0:DEPTH-1];

    // RAM Memory (decrypted weights)
    reg [N-1:0] ram_mem [0:DEPTH-1];

    // ROM selection based on active_model
    always @(posedge clk) begin
        case (active_model)
            2'b01: rom_data <= rom_model_a[rom_addr];
            2'b10: rom_data <= rom_model_b[rom_addr];
            default: rom_data <= 8'h00;
        endcase
    end

    // RAM logic
    always @(posedge clk) begin
        if (ram_write_en) begin
            ram_mem[ram_addr] <= ram_din;
        end
        ram_dout <= ram_mem[ram_addr];
    end

    // Initialize both ROMs
    initial begin
        $readmemh("rom_model_a.mem", rom_model_a);
        $readmemh("rom_model_b.mem", rom_model_b);
    end
endmodule
