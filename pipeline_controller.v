module pipeline_controller_streaming #(
    parameter TOTAL_INPUTS = 16
)(
    input wire clk,
    input wire rst,
    input wire start,

    input wire valid_out1,
    input wire valid_out2,
    input wire valid_out3,

    output reg valid_in1,
    output reg valid_in2,
    output reg valid_in3,
    output reg pipeline_done,

    output reg [$clog2(TOTAL_INPUTS)-1:0] input_index
);
    reg [$clog2(TOTAL_INPUTS):0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            input_index <= 0;
            pipeline_done <= 0;
        end else if (start && !pipeline_done) begin
            counter <= counter + 1;
            input_index <= input_index + 1;
            if (counter >= TOTAL_INPUTS) begin
                pipeline_done <= 1;
            end
        end
    end

    always @(*) begin
        valid_in1 = start && !pipeline_done;
        valid_in2 = valid_out1;
        valid_in3 = valid_out2;
    end
endmodule
