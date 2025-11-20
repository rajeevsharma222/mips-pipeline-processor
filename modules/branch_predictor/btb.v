
module btb #(
    parameter INDEX_BITS = 6,   // 2^INDEX_BITS entries (default 64)
    parameter TAG_BITS   = 20   // width of tag bits (default PC[31:12])
)(
    input  wire                        clk,
    input  wire                        reset,
    // lookup
    input  wire [INDEX_BITS-1:0]       pc_index,
    input  wire [TAG_BITS-1:0]         pc_tag,
    output wire                        hit,
    output wire [31:0]                 target_out,
    // update
    input  wire                        update_en,
    input  wire [INDEX_BITS-1:0]       update_index,
    input  wire [TAG_BITS-1:0]         update_tag,
    input  wire [31:0]                 update_target
);

    localparam N = (1<<INDEX_BITS);
    integer i;

    reg [TAG_BITS-1:0] tag_array [0:N-1];
    reg [31:0]         target_array [0:N-1];
    reg                valid [0:N-1];

    wire [TAG_BITS-1:0] lookup_tag = tag_array[pc_index];
    wire                lookup_valid = valid[pc_index];

    assign hit = lookup_valid && (lookup_tag == pc_tag);
    assign target_out = target_array[pc_index];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < N; i = i + 1) begin
                valid[i] <= 1'b0;
                tag_array[i] <= {TAG_BITS{1'b0}};
                target_array[i] <= 32'h0;
            end
        end else if (update_en) begin
            valid[update_index] <= 1'b1;
            tag_array[update_index] <= update_tag;
            target_array[update_index] <= update_target;
        end
    end

endmodule
