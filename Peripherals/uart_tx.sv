module uart_tx #(
    parameter int unsigned CLKS_PER_BIT = 10417 //Basys3 Clock Frequency (100MHz) / Baud Rate (9600) ≈ 10417
)(
    input logic clk,
    input logic rst,
    input logic [7:0] tx_data,
    input logic tx_start,
    output logic tx_busy,
    output logic tx_serial
);

    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_START_BIT,
        STATE_DATA_BITS,
        STATE_STOP_BIT
    } state_e;

    state_e state;
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] tx_data_copy;

    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= STATE_IDLE;
            tx_serial   <= 1'b1;
            tx_busy     <= 1'b0;
            clk_count   <= '0;
            bit_index   <= '0;
            tx_data_copy <= '0;
        end
        
        else begin
            unique case(state)
                STATE_IDLE: begin
                    tx_serial <= 1'b1;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (tx_start) begin
                        tx_data_copy <= tx_data;
                        tx_busy <= 1'b1;
                        state <= STATE_START_BIT;
                    end
                    else
                        tx_busy <= 1'b0;
                end

                STATE_START_BIT: begin
                    tx_serial <= 1'b0;    //Setting start bit as 0

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state <= STATE_DATA_BITS;
                    end
                    else
                        clk_count <= clk_count + 1;
                end

                STATE_DATA_BITS: begin
                    tx_serial <= tx_data_copy[bit_index];

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;

                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state <= STATE_STOP_BIT;
                        end
                        else
                            bit_index <= bit_index + 1;
                    end
                    else
                        clk_count <= clk_count + 1;
                end

                STATE_STOP_BIT: begin
                    tx_serial <= 1'b1;    //Setting stop bit as 1

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        tx_busy <= 1'b0;
                        state <= STATE_IDLE;
                    end
                    else
                        clk_count <= clk_count + 1;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule