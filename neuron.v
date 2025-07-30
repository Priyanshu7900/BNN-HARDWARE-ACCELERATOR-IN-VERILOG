`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: YourName/Sparkonics Hackathon
// Engineer: [Your Name]
// 
// Create Date: 2025-07-11
// Module Name: neuron_unit
// Project Name: Secure BNN Accelerator
// Target Devices: FPGA/ASIC
// Description: 
//   A binary neuron unit performing:
//     - XNOR between inputs and weights
//     - Popcount of XNOR result
//     - Threshold-based activation
//   Designed for Binary Neural Network acceleration.
//
// Dependencies: None
//
//////////////////////////////////////////////////////////////////////////////////

module neuron_unit #(
    parameter N = 16               // Input vector width
)(
    input wire clk,               // Clock
    input wire rst,               // Reset (active high)
    input wire [N-1:0] inputs,    // Binary input vector
    input wire [N-1:0] weights,   // Binary weight vector
    input wire [7:0] threshold,   // Activation threshold
    input wire valid_in,          // Input valid signal
    output reg out,               // Neuron output (1 or 0)
    output reg valid_out,         // Output valid signal
    output reg [7:0] debug_popcount // Optional: For test/debugging
);

    // Intermediate wires
    reg [N-1:0] xnor_result;
    integer i;
    reg [7:0] popcnt;

    // Combinational XNOR + Popcount logic
    always @(*) begin
        xnor_result = ~(inputs ^ weights); // bitwise XNOR
        popcnt = 0;

        for (i = 0; i < N; i = i + 1) begin
            popcnt = popcnt + xnor_result[i];
        end
    end

    // Registered output logic (optional pipeline stage)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 1'b0;
            valid_out <= 1'b0;
            debug_popcount <= 8'd0;
        end else begin
            if (valid_in) begin
                out <= (popcnt >= threshold) ? 1'b1 : 1'b0;
                debug_popcount <= popcnt;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
