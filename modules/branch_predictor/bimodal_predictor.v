module bimodal_predictor #(
    parameter INDEX_BITS = 8 // 2^INDEX_BITS entries, default 256
)(
    input  wire                     clk,
    input  wire                     reset,
    // read port
    input  wire [INDEX_BITS-1:0]    pc_index,      // index derived from PC (combinational)
    output wire                     predict_taken, // read output (msb of counter)
    // update port (synchronous): update entry at upd_index
    input  wire                     update_en,
    input  wire [INDEX_BITS-1:0]    update_index,
    input  wire                     update_taken
);

    localparam N = (1<<INDEX_BITS);
    integer i;

    reg [1:0] pht [0:N-1];

    // combinational read
    assign predict_taken = pht[pc_index][1];

    // synchronous init / update
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < N; i = i + 1)
                pht[i] <= 2'b01; // weakly not-taken
        end else if (update_en) begin
            if (update_taken) begin
                if (pht[update_index] != 2'b11)
                    pht[update_index] <= pht[update_index] + 1'b1;
            end else begin
                if (pht[update_index] != 2'b00)
                    pht[update_index] <= pht[update_index] - 1'b1;
            end
        end
    end

endmodule
