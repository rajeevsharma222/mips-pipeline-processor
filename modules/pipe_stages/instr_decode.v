module instr_decode(
    input clk,
    input reset,
    input [31:0] instr,
    input [31:0] pc_plus_4,
    input [31:0] reg_wr_data,
    input [4:0] reg_wr_addr,
    input [31:0] mem_alu_result,
    input reg_wr_en,
    input flush_ex,
    input forwardA_id,
    input forwardB_id,
    input [31:0] if_id_pc,

    // predictor/BTB update outputs (connect to instr_fetch inputs)
    output pred_update_en,
    output [7:0] pred_update_index,
    output pred_update_taken,
    output btb_update_en,
    output [5:0] btb_update_index,
    output [19:0] btb_update_tag,
    output [31:0] btb_update_target,

    output id_jump,
    output id_ex_mem_to_reg_wr,
    output id_ex_mem_wr_en,
    output id_ex_alu_src_sel,
    output id_ex_reg_wr_en,
    output id_pc_src,
    output id_branch,
    output [2:0] id_ex_alu_ctrl,
    output [4:0] id_ex_reg_wr_addr,
    output [4:0] id_rs,
    output [4:0] id_rt,
    output [4:0] id_ex_rs,
    output [4:0] id_ex_rt,
    output [31:0] id_ex_reg_data1,
    output [31:0] id_ex_reg_data2,
    output [31:0] id_ex_sign_imm_ext,
    output [31:0] id_pc_branch,
    output [31:0] id_pc_jump
);

    wire mem_to_reg_wr;
    wire mem_wr_en;
    wire alu_src_sel;
    wire reg_file_dst_sel;
    wire reg_wr_en_temp;
    wire branch;
    wire [2:0] alu_ctrl;
    wire [27:0] shl_jump_addr;
    wire [4:0] reg_wr_addr_temp;
    wire [31:0] sign_imm_ext;
    wire [31:0] sign_imm_ext_shl;
    wire [31:0] reg_rd_data1;
    wire [31:0] reg_rd_data2;
    wire [31:0] reg_data1;
    wire [31:0] reg_data2;

    assign shl_jump_addr = (instr[25:0] << 2);

    assign id_branch = branch;
    assign id_pc_jump = {pc_plus_4[31:28], shl_jump_addr};
    assign id_pc_src = branch && (reg_data1 == reg_data2);
    assign id_rs = instr[25:21];
    assign id_rt = instr[20:16];

    control_unit control_unit_inst(
        .funct(instr[5:0]),
        .opcode(instr[31:26]),
        .mem_to_reg_wr(mem_to_reg_wr),
        .branch(branch),
        .mem_wr_en(mem_wr_en),
        .jump(id_jump),
        .alu_src_sel(alu_src_sel),
        .reg_file_dst_sel(reg_file_dst_sel),
        .reg_wr_en(reg_wr_en_temp),
        .alu_ctrl(alu_ctrl)
    );

    reg_file reg_file_inst(
        .clk(clk),
        .wr_en(reg_wr_en),
        .rd_addr1(instr[25:21]),
        .rd_addr2(instr[20:16]),
        .wr_data(reg_wr_data),
        .wr_addr(reg_wr_addr),
        .rd_data1(reg_rd_data1),
        .rd_data2(reg_rd_data2)
    );

    mux2 reg_data1_mux_inst(
        .a(reg_rd_data1),
        .b(mem_alu_result),
        .sel(forwardA_id),
        .out(reg_data1)
    );

    mux2 reg_data2_mux_inst(
        .a(reg_rd_data2),
        .b(mem_alu_result),
        .sel(forwardB_id),
        .out(reg_data2)
    );

    sign_ext sign_imm_ext_inst(
        .a(instr[15:0]),
        .y(sign_imm_ext)
    );

    shl_2 sign_imm_ext_shl_inst(
        .shl_in(sign_imm_ext),
        .shl_out(sign_imm_ext_shl)
    );

    adder pc_branch_inst(
        .a(pc_plus_4),
        .b(sign_imm_ext_shl),
        .sum(id_pc_branch)
    );

    mux2 reg_file_dst_mux_inst(
        .a(instr[20:16]),
        .b(instr[15:11]),
        .sel(reg_file_dst_sel),
        .out(reg_wr_addr_temp)
    );

    d_ff id_ex_mem_wr_en_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(mem_wr_en),
        .q(id_ex_mem_wr_en)
    ); defparam id_ex_mem_wr_en_inst.WIDTH=1;

    d_ff id_ex_mem_to_reg_wr_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(mem_to_reg_wr),
        .q(id_ex_mem_to_reg_wr)
    ); defparam id_ex_mem_to_reg_wr_inst.WIDTH=1;

    d_ff id_ex_reg_wr_en_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(reg_wr_en_temp),
        .q(id_ex_reg_wr_en)
    ); defparam id_ex_reg_wr_en_inst.WIDTH=1;

    d_ff id_ex_alu_src_sel_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(alu_src_sel),
        .q(id_ex_alu_src_sel)
    ); defparam id_ex_alu_src_sel_inst.WIDTH=1;

    d_ff id_ex_alu_ctrl_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(alu_ctrl),
        .q(id_ex_alu_ctrl)
    ); defparam id_ex_alu_ctrl_inst.WIDTH=3;

    d_ff id_ex_rs_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(instr[25:21]),
        .q(id_ex_rs)
    ); defparam id_ex_rs_inst.WIDTH=5;

    d_ff id_ex_rt_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(instr[20:16]),
        .q(id_ex_rt)
    ); defparam id_ex_rt_inst.WIDTH=5;

    d_ff id_ex_reg_wr_addr_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(reg_wr_addr_temp),
        .q(id_ex_reg_wr_addr)
    ); defparam id_ex_reg_wr_addr_inst.WIDTH=6;

    d_ff id_ex_reg_data1_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(reg_data1),
        .q(id_ex_reg_data1)
    );

    d_ff id_ex_reg_data2_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(reg_data2),
        .q(id_ex_reg_data2)Added branch prediction and BTB update functionality.
    );

    d_ff id_ex_sign_imm_ext_inst(
        .clk(clk),
        .reset((reset | flush_ex)),
        .en(1'b0),
        .d(sign_imm_ext),
        .q(id_ex_sign_imm_ext)
    );

    assign pred_update_en    = id_branch;                     // update direction predictor on every branch resolution
    assign pred_update_index = if_id_pc[9:2];
    assign pred_update_taken = id_pc_src;                     // resolved taken/not-taken

    assign btb_update_en     = id_branch && id_pc_src;        // update BTB only on taken branches
    assign btb_update_index  = if_id_pc[11:6];
    assign btb_update_tag    = if_id_pc[31:12];
    assign btb_update_target = id_pc_branch;                  // branch target computed earlier

endmodule
