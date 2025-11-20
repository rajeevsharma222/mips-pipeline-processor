module mips_pipeline(
    input clk,
    input reset
);
    
    wire wb_reg_wr_en;
    wire id_ex_mem_to_reg_wr;
    wire ex_mem_to_reg_wr;
    wire id_ex_mem_wr_en;
    wire id_ex_alu_src_sel;
    wire id_ex_reg_wr_en;
    wire ex_reg_wr_en;
    wire [31:0] id_pc_branch;
    wire [31:0] id_pc_jump;
    wire [31:0] if_id_pc_plus_4;
    wire [31:0] if_id_instr;
    wire [31:0] wb_reg_wr_data;
    wire [4:0] wb_reg_wr_addr;
    wire [2:0] id_ex_alu_ctrl;
    wire [4:0] id_ex_reg_wr_addr;
    wire [4:0] ex_reg_wr_addr;
    wire [31:0] id_ex_reg_data1;
    wire [31:0] id_ex_reg_data2;
    wire [31:0] id_ex_sign_imm_ext;
    wire id_jump;
    wire id_pc_src;
    wire id_branch;
    wire ex_mem_mem_to_reg_wr;
    wire ex_mem_mem_wr_en;
    wire ex_mem_reg_wr_en;
    wire mem_reg_wr_en;
    wire mem_mem_to_reg_wr;
    wire [4:0] mem_reg_wr_addr;
    wire [4:0] id_rs;
    wire [4:0] id_rt;
    wire [4:0] ex_rs;
    wire [4:0] ex_rt;
    wire [4:0] id_ex_rs;
    wire [4:0] id_ex_rt;
    wire [4:0] ex_mem_reg_wr_addr;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] mem_alu_result;
    wire [31:0] ex_mem_mem_wr_data;
    wire [31:0] ex_mem_wr_data;
    wire mem_wb_reg_wr_en;
    wire mem_wb_mem_to_reg_wr;
    wire [4:0] mem_wb_reg_wr_addr;
    wire [31:0] mem_wb_mem_rd_data;
    wire [31:0] mem_wb_alu_result;
    wire stall_id;
    wire stall_if;
    wire [1:0] forwardA_ex;
    wire [1:0] forwardB_ex;
    wire forwardA_id;
    wire forwardB_id;
    wire flush_ex;

    
    wire [31:0] if_id_pc;            
    // predictor update
    wire        pred_update_en;
    wire [7:0]  pred_update_index;
    wire        pred_update_taken;
    // BTB update
    wire        btb_update_en;
    wire [5:0]  btb_update_index;
    wire [19:0] btb_update_tag;
    wire [31:0] btb_update_target;

   
    instr_fetch instr_fetch_inst(
        .clk(clk),
        .reset(reset),
        .jump(id_jump),
        .pc_src(id_pc_src),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .pc_branch(id_pc_branch),
        .pc_jump(id_pc_jump),

        // update inputs (driven by instr_decode)
        .pred_update_en(pred_update_en),
        .pred_update_index(pred_update_index),
        .pred_update_taken(pred_update_taken),
        .btb_update_en(btb_update_en),
        .btb_update_index(btb_update_index),
        .btb_update_tag(btb_update_tag),
        .btb_update_target(btb_update_target),

        // IF/ID outputs
        .if_id_pc(if_id_pc),
        .if_id_pc_plus_4(if_id_pc_plus_4),
        .if_id_instr(if_id_instr)
    );
    
   
    instr_decode instr_decode_inst(
        .clk(clk),
        .reset(reset),
        .instr(if_id_instr),
        .pc_plus_4(if_id_pc_plus_4),
        .reg_wr_data(wb_reg_wr_data),
        .reg_wr_addr(wb_reg_wr_addr),
        .mem_alu_result(mem_alu_result),
        .reg_wr_en(wb_reg_wr_en),
        .forwardA_id(forwardA_id),
        .forwardB_id(forwardB_id),
        .flush_ex(flush_ex),

        .if_id_pc(if_id_pc),

        // predictor/BTB update outputs (wired back to instr_fetch)
        .pred_update_en(pred_update_en),
        .pred_update_index(pred_update_index),
        .pred_update_taken(pred_update_taken),
        .btb_update_en(btb_update_en),
        .btb_update_index(btb_update_index),
        .btb_update_tag(btb_update_tag),
        .btb_update_target(btb_update_target),

        // existing outputs
        .id_jump(id_jump),
        .id_ex_mem_to_reg_wr(id_ex_mem_to_reg_wr),
        .id_ex_mem_wr_en(id_ex_mem_wr_en),
        .id_ex_alu_src_sel(id_ex_alu_src_sel),
        .id_branch(id_branch),
        .id_ex_reg_wr_en(id_ex_reg_wr_en),
        .id_pc_src(id_pc_src),
        .id_pc_branch(id_pc_branch),
        .id_pc_jump(id_pc_jump),
        .id_ex_alu_ctrl(id_ex_alu_ctrl),
        .id_ex_reg_wr_addr(id_ex_reg_wr_addr),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_ex_rs(id_ex_rs),
        .id_ex_rt(id_ex_rt),
        .id_ex_reg_data1(id_ex_reg_data1),
        .id_ex_reg_data2(id_ex_reg_data2),
        .id_ex_sign_imm_ext(id_ex_sign_imm_ext)
    );
    
    // -------------------------
    // execute
    // -------------------------
    execute execute_inst(
        .clk(clk),
        .reset(reset),
        .mem_to_reg_wr(id_ex_mem_to_reg_wr),
        .reg_wr_en(id_ex_reg_wr_en),
        .mem_wr_en(id_ex_mem_wr_en),
        .alu_src_sel(id_ex_alu_src_sel),
        .alu_ctrl(id_ex_alu_ctrl),
        .forwardA_ex(forwardA_ex),
        .forwardB_ex(forwardB_ex),
        .id_ex_rs(id_ex_rs),
        .id_ex_rt(id_ex_rt),
        .reg_wr_addr(id_ex_reg_wr_addr),
        .mem_alu_result(mem_alu_result),
        .wb_reg_wr_data(wb_reg_wr_data),
        .reg_data1(id_ex_reg_data1),
        .reg_data2(id_ex_reg_data2),
        .sign_imm_ext(id_ex_sign_imm_ext),
        .ex_mem_mem_to_reg_wr(ex_mem_mem_to_reg_wr),
        .ex_mem_mem_wr_en(ex_mem_mem_wr_en),
        .ex_mem_reg_wr_en(ex_mem_reg_wr_en),
        .ex_mem_to_reg_wr(ex_mem_to_reg_wr),
        .ex_reg_wr_en(ex_reg_wr_en),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_reg_wr_addr(ex_reg_wr_addr),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_mem_reg_wr_addr(ex_mem_reg_wr_addr),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_mem_wr_data(ex_mem_mem_wr_data)
    );
    
    // -------------------------
    // memory_write
    // -------------------------
    memory_write memory_write_inst(
        .clk(clk),
        .reset(reset),
        .reg_wr_en(ex_mem_reg_wr_en),
        .mem_wr_en(ex_mem_mem_wr_en),
        .mem_to_reg_wr(ex_mem_mem_to_reg_wr),
        .reg_wr_addr(ex_mem_reg_wr_addr),
        .alu_result(ex_mem_alu_result),
        .mem_wr_data(ex_mem_mem_wr_data),
        .mem_wb_reg_wr_en(mem_wb_reg_wr_en),
        .mem_wb_mem_to_reg_wr(mem_wb_mem_to_reg_wr),
        .mem_reg_wr_en(mem_reg_wr_en),
        .mem_alu_result(mem_alu_result),
        .mem_mem_to_reg_wr(mem_mem_to_reg_wr),
        .mem_reg_wr_addr(mem_reg_wr_addr),
        .mem_wb_reg_wr_addr(mem_wb_reg_wr_addr),
        .mem_wb_mem_rd_data(mem_wb_mem_rd_data),
        .mem_wb_alu_result(mem_wb_alu_result)
    );
    
    // -------------------------
    // write_back
    // -------------------------
    write_back write_back_inst(
        .reg_wr_en(mem_wb_reg_wr_en),
        .mem_to_reg_wr(mem_wb_mem_to_reg_wr),
        .alu_result(mem_wb_alu_result),
        .mem_rd_data(mem_wb_mem_rd_data),
        .reg_wr_addr(mem_wb_reg_wr_addr),
        .wb_reg_wr_en(wb_reg_wr_en),
        .wb_reg_wr_data(wb_reg_wr_data),
        .wb_reg_wr_addr(wb_reg_wr_addr)
    );
    
    // -------------------------
    // hazard_unit
    // -------------------------
    hazard_unit hazard_unit_inst(
        .id_branch(id_branch),
        .ex_mem_to_reg_wr(ex_mem_to_reg_wr),
        .mem_mem_to_reg_wr(mem_mem_to_reg_wr),
        .ex_reg_wr_en(ex_reg_wr_en),
        .mem_reg_wr_en(mem_reg_wr_en),
        .wb_reg_wr_en(wb_reg_wr_en),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_reg_wr_addr(ex_reg_wr_addr),
        .mem_reg_wr_addr(mem_reg_wr_addr),
        .wb_reg_wr_addr(wb_reg_wr_addr),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .flush_ex(flush_ex),
        .forwardA_ex(forwardA_ex),
        .forwardA_id(forwardA_id),
        .forwardB_id(forwardB_id),
        .forwardB_ex(forwardB_ex)
    );
        
endmodule
