module instr_fetch(
    input clk,
    input reset,
    input jump,
    input pc_src,
    input stall_if,
    input stall_id,
    input [31:0] pc_branch,
    input [31:0] pc_jump,

    // predictor/BTB update inputs (driven from ID stage)
    input  wire                    pred_update_en,
    input  wire [7:0]              pred_update_index, // matches INDEX_BITS below
    input  wire                    pred_update_taken,
    input  wire                    btb_update_en,
    input  wire [5:0]              btb_update_index,  // matches BTB_INDEX_BITS below
    input  wire [19:0]             btb_update_tag,    // matches BTB_TAG_BITS below
    input  wire [31:0]             btb_update_target,

    // outputs to IF/ID
    output [31:0] if_id_pc,       
    output [31:0] if_id_pc_plus_4,
    output [31:0] if_id_instr
);

    // parameters for predictor/BTB indexing
    localparam PHT_INDEX_BITS = 8; // 256-entry predictor
    localparam BTB_INDEX_BITS = 6; // 64-entry BTB
    localparam BTB_TAG_BITS   = 20;

    wire [31:0] instr;
    wire [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] next_pc_br;
    wire [31:0] next_pc;

    // predictor/BTB read wires
    wire predict_taken;
    wire btb_hit;
    wire [31:0] btb_target;

    // derive indices/tags from current PC (word-addressed)
    wire [PHT_INDEX_BITS-1:0] if_pc_pred_index = pc[9:2];   // bits [9:2] -> 8 bits
    wire [BTB_INDEX_BITS-1:0] if_btb_index      = pc[11:6]; // bits [11:6] -> 6 bits
    wire [BTB_TAG_BITS-1:0]   if_btb_tag        = pc[31:12]; // tag bits

    // choose target: if predictor says taken and BTB has hit -> use BTB target
    wire [31:0] predicted_pc = (predict_taken & btb_hit) ? btb_target : next_pc_br;

    // existing muxes
    mux2 pc_branch_mux_inst(
        .a(pc_plus_4),
        .b(pc_branch),
        .sel(pc_src),
        .out(next_pc_br)
    );

    mux2 pc_jump_mux_inst(
        .a(predicted_pc),
        .b(pc_jump),
        .sel(jump),
        .out(next_pc)
    );

    d_ff pc_ff_inst(
        .clk(clk),
        .reset(reset),
        .en(stall_if),
        .d(next_pc),
        .q(pc)
    );

    instr_mem instr_mem_inst(
        .instr_addr(pc[7:2]),
        .instr(instr)
    );

    adder pc_plus_4_inst(
        .a(4),
        .b(pc),
        .sum(pc_plus_4)
    );

    // IF/ID pipeline registers (pc, pc_plus_4, instr)
    d_ff if_id_pc_inst(
        .clk(clk),
        .reset((reset | pc_src)),
        .en(stall_id),
        .d(pc),
        .q(if_id_pc)
    );

    d_ff if_id_pc_plus_4_inst(
        .clk(clk),
        .reset((reset | pc_src)),
        .en(stall_id),
        .d(pc_plus_4),
        .q(if_id_pc_plus_4)
    );

    d_ff if_id_instr_inst(
        .clk(clk),
        .reset((reset | pc_src)),
        .en(stall_id),
        .d(instr),
        .q(if_id_instr)
    );

    // instantiate predictor (read in IF stage, update inputs from ID)
    bimodal_predictor #(.INDEX_BITS(PHT_INDEX_BITS)) predictor_inst (
        .clk(clk),
        .reset(reset),
        .pc_index(if_pc_pred_index),
        .predict_taken(predict_taken),
        .update_en(pred_update_en),
        .update_index(pred_update_index),
        .update_taken(pred_update_taken)
    );

    // instantiate BTB (read in IF stage, update inputs from ID)
    btb #(.INDEX_BITS(BTB_INDEX_BITS), .TAG_BITS(BTB_TAG_BITS)) btb_inst (
        .clk(clk),
        .reset(reset),
        .pc_index(if_btb_index),
        .pc_tag(if_btb_tag),
        .hit(btb_hit),
        .target_out(btb_target),
        .update_en(btb_update_en),
        .update_index(btb_update_index),
        .update_tag(btb_update_tag),
        .update_target(btb_update_target)
    );

endmodule
