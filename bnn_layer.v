`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Sparkonics Hackathon
// Engineer: Priyanshu Gupta
// 
// Create Date: 2025-07-11
// Module Name: bnn_layer
// Description: 
//   A binary neural network layer containing multiple parallel neurons.
//   Each neuron takes the same input but uses different weights and threshold.
//   Outputs are activated based on popcount ≥ threshold.
//
//////////////////////////////////////////////////////////////////////////////////

module bnn_layer #(
    parameter N = 16,         // Input bit-width per neuron
    parameter NEURONS = 8     // Number of parallel neurons
)(
    input wire clk,
    input wire rst,
    input wire valid_in,                          // Valid signal for new input
    input wire [N-1:0] input_vector,              // Common input to all neurons
    input wire [NEURONS*N-1:0] weights_flat,      // Flattened weights for all neurons
    input wire [8*NEURONS-1:0] thresholds_flat,   // Flattened thresholds (8-bit per neuron)
    
    output reg [NEURONS-1:0] output_vector,       // Output from each neuron
    output reg valid_out,                         // Indicates outputs are valid
    output reg [8*NEURONS-1:0] debug_popcounts    // Optional: Debug popcount output
);

    // Internal wire to hold outputs from neurons
    wire [NEURONS-1:0] neuron_outputs;
    wire [7:0] popcount_outputs [0:NEURONS-1]; // Array for popcount debug

    genvar i;
    generate
        for (i = 0; i < NEURONS; i = i + 1) begin : neuron_array
            wire [N-1:0] weight_i;
            wire [7:0] threshold_i;

            assign weight_i = weights_flat[(i+1)*N-1 -: N];
            assign threshold_i = thresholds_flat[(i+1)*8-1 -: 8];

            neuron_unit #(.N(N)) neuron_inst (
                .clk(clk),
                .rst(rst),
                .inputs(input_vector),
                .weights(weight_i),
                .threshold(threshold_i),
                .valid_in(valid_in),
                .out(neuron_outputs[i]),
                .valid_out(), // We use shared valid_out below
                .debug_popcount(popcount_outputs[i])
            );
        end
    endgenerate

    integer j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output_vector <= 0;
            valid_out <= 0;
            debug_popcounts <= 0;
        end else begin
            if (valid_in) begin
                output_vector <= neuron_outputs;
                valid_out <= 1;

                for (j = 0; j < NEURONS; j = j + 1) begin
                    debug_popcounts[(j+1)*8-1 -: 8] <= popcount_outputs[j];
                end
            end else begin
                valid_out <= 0;
            end
        end
    end

endmodule
