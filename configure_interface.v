//////////////////////////////////////////////////////////////////////////////////
// Engineer: Priyanshu Gupta
// Module Name: config_interface
// Description:
//   FSM-based configuration interface for selecting models at runtime.
//   Supports 2 models (Model A and Model B) but easily expandable.
//   Accepts simple command input and raises flags to reload weights.
//
//////////////////////////////////////////////////////////////////////////////////

module config_interface (
    input wire clk,
    input wire rst,

    input wire [1:0] command,      // 2-bit command: 00=NOP, 01=Model A, 10=Model B
    input wire command_valid,      // High when a valid command is available

    output reg [1:0] active_model, // 01 = Model A, 10 = Model B
    output reg reload_weights      // Pulse high to trigger weight reload
);

    // FSM states
    typedef enum reg [1:0] {
        IDLE = 2'b00,
        MODEL_A = 2'b01,
        MODEL_B = 2'b10
    } state_t;

    state_t state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            active_model <= 2'b00;
            reload_weights <= 0;
        end else begin
            reload_weights <= 0; // Default low (one-cycle pulse)
            if (command_valid) begin
                case (command)
                    2'b01: begin
                        if (state != MODEL_A) begin
                            state <= MODEL_A;
                            active_model <= 2'b01;
                            reload_weights <= 1;
                        end
                    end
                    2'b10: begin
                        if (state != MODEL_B) begin
                            state <= MODEL_B;
                            active_model <= 2'b10;
                            reload_weights <= 1;
                        end
                    end
                    default: begin
                        // NOP or invalid
                    end
                endcase
            end
        end
    end

endmodule
