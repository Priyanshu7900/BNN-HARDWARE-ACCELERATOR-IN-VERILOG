//////////////////////////////////////////////////////////////////////////////////
// Engineer: Priyanshu Gupta
// Module Name: performance_monitor
// Description:
//   Monitors performance of BNN pipeline:
//     - Counts latency per inference
//     - Measures total clock cycles
//     - Tracks how many inputs were processed
//
//////////////////////////////////////////////////////////////////////////////////

module performance_monitor #(
    parameter MAX_INPUTS = 16
)(
    input wire clk,
    input wire rst,
    input wire start_inference,     // Pulse high when input starts
    input wire inference_done,      // Pulse high when output ready

    output reg [15:0] latency_cycles,
    output reg [31:0] total_cycles,
    output reg [$clog2(MAX_INPUTS)-1:0] input_count
);

    // Internal
    reg [15:0] current_latency;
    reg is_running;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            latency_cycles <= 0;
            total_cycles <= 0;
            input_count <= 0;
            current_latency <= 0;
            is_running <= 0;
        end else begin
            // Total cycles tracker (global)
            total_cycles <= total_cycles + 1;

            if (start_inference) begin
                is_running <= 1;
                current_latency <= 0;
            end

            if (is_running) begin
                current_latency <= current_latency + 1;
            end

            if (inference_done) begin
                is_running <= 0;
                latency_cycles <= current_latency;
                input_count <= input_count + 1;
            end
        end
    end

endmodule
