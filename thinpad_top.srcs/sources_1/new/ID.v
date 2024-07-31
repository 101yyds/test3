module ID(
    input  wire         clk                ,
    input  wire         reset              ,
    input  wire         valid              ,

    output wire         stall_current_stage,//输出给IF模块
    input  wire         stall_next_stage   ,//来自EX模块

    input  wire [31: 0] pc                 ,//来自IF模块
    input  wire [31: 0] inst               ,//来自IF模块，32位指令码

    output wire [31: 0] operand1_out       ,
    output wire [31: 0] operand2_out       ,
    output wire [12: 0] alu_op_out         ,

    output wire         branch_flag        ,
    (*use_dep="yes"*)
    output wire [31: 0] branch_addr        ,

    output wire [ 4: 0] reg_waddr_out      ,//目标寄存器代号
    output wire         reg_we_out         ,//写使能输出
    input  wire [31: 0] reg_wdata_ex       ,//来自EX模块

    input  wire [ 4: 0] reg_waddr_mem      ,//来自EX模块
    input  wire         reg_we_mem         ,//来自EX模块
    input  wire [31: 0] reg_wdata_mem      ,//来自EX模块

    input  wire [ 4: 0] reg_waddr_wb       ,//来自MEM模块
    input  wire         reg_we_wb          ,//来自MEM模块
    input  wire [31: 0] reg_wdata_wb       ,//来自WB模块

    output wire         mem_load_out       ,//内部使用
    input  wire         mem_load_mem       ,//来自MEM模块
    input  wire [31: 0] mem_result         ,//来自MEM模块

    output wire         valid_out          ,//输出给EX模块

    output wire [31: 0] data_ram_wdata_out ,//输出给EX模块
    output wire [ 3: 0] data_ram_be_out    ,
    output wire         data_ram_ce_out    ,
    output wire         data_ram_oe_out    ,
    output wire         data_ram_we_out    ,//4个信号均输出给EX模块

    input  wire         stall_if           ,//来自IF模块的stall_current_stage
    (*use_dep="yes"*)
    output wire [31: 0] nextpc              //输出给IF模块
);

    wire [ 5: 0] op_31_26;
    wire [ 3: 0] op_25_22;
    wire [ 1: 0] op_21_20;
    wire [ 4: 0] op_19_15;

    wire [63: 0] op_31_26_d;
    wire [15: 0] op_25_22_d;
    wire [ 3: 0] op_21_20_d;
    wire [31: 0] op_19_15_d;

    wire [11: 0] i12;
    wire [19: 0] i20;
    wire [15: 0] i16;
    wire [25: 0] i26;
    wire [ 4: 0] ui5;

    wire         inst_addi_w, inst_lu12i_w, inst_add_w, inst_st_w, inst_ld_w, inst_bne, inst_pcaddu12i, inst_or, inst_ori, inst_andi, inst_xor, inst_beq, inst_st_b, inst_ld_b, inst_sltu, inst_sra_w, inst_bltu, inst_sub_w, inst_and, inst_srli_w, inst_slli_w, inst_jirl, inst_b, inst_bl, inst_mul_w, inst_mod_w, inst_mod_wu;
    
    wire [31: 0] rf_rdata1, rf_rdata2, br_offs, jirl_offs, alu_src1, alu_src2, imm;
    reg  [31: 0] rj_value, rkd_value;

    wire [ 2: 0] addr1_is_eq, addr2_is_eq;

    wire [ 4: 0] rd, rj, rk, dest, rf_raddr1, rf_raddr2;

    wire         gr_we, rf_we;

    wire         rj_eq_rd;

    wire [12: 0] alu_op;

    wire         inst_no_rf1 /*没有第一个寄存器代号*/,inst_no_rf2, src_reg_is_rd, dst_is_r1, src2_is_4;

    wire [ 3: 0] data_sram_be;
    wire [31: 0] data_sram_wdata;
    wire         data_sram_we;
    wire         data_sram_oe;
    wire         data_sram_ce;

    wire         need_ui5 ;
    wire         need_si12;
    wire         need_si16;
    wire         need_si20;
    wire         need_si26;
    wire         need_ui12;

    wire res_from_mem, src1_is_pc, src2_is_imm, rj_lt_rkd_s, rj_lt_rkd_u, mem_we, dst_conflict, dst2_conflict, dst1_conflict;
    // ***********************************************************
    // * INST GEN
    // ***********************************************************

    assign op_31_26         = inst[31:26];
    assign op_25_22         = inst[25:22];
    assign op_21_20         = inst[21:20];
    assign op_19_15         = inst[19:15];

    decoder_6_64 u_dec0(
        .in  ( op_31_26   ), 
        .out ( op_31_26_d )
    );
    decoder_4_16 u_dec1(
        .in  ( op_25_22   ), 
        .out ( op_25_22_d )
    );
    decoder_2_4  u_dec2(
        .in  ( op_21_20   ), 
        .out ( op_21_20_d )
    );
    decoder_5_32 u_dec3(
        .in  ( op_19_15   ), 
        .out ( op_19_15_d )
    );

    assign inst_add_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];      // read rj, rk, write rd
    assign inst_addi_w      = op_31_26_d[6'h00] & op_25_22_d[4'ha];                                             // read rj    , write rd
    assign inst_and         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];      // read rj, rk, write rd
    assign inst_andi        = op_31_26_d[6'h00] & op_25_22_d[4'hd];                                             // read rj    , write rd
    assign inst_b           = op_31_26_d[6'h14];                                                                // read -     , write -
    assign inst_beq         = op_31_26_d[6'h16];                                                                // read rj, rd, write -
    assign inst_bl          = op_31_26_d[6'h15];                                                                // read -     , write r1
    assign inst_bltu        = op_31_26_d[6'h1a];                                                                // read rj, rd, write -
    assign inst_bne         = op_31_26_d[6'h17];                                                                // read rj, rd, write -
    assign inst_jirl        = op_31_26_d[6'h13];                                                                // read rj    , write rd
    assign inst_ld_b        = op_31_26_d[6'h0a] & op_25_22_d[4'h0];                                             // read rj    , write rd
    assign inst_ld_w        = op_31_26_d[6'h0a] & op_25_22_d[4'h2];                                             // read rj    , write rd
    assign inst_lu12i_w     = op_31_26_d[6'h05] & ~inst[25];                                                    // read -     , write rd
    assign inst_mod_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];      // read rj, rk, write rd
    assign inst_mod_wu      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];      // read rj, rk, write rd
    assign inst_mul_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];      // read rj, rk, write rd
    assign inst_or          = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];      // read rj, rk, write rd
    assign inst_ori         = op_31_26_d[6'h00] & op_25_22_d[4'he];                                             // read rj    , write rd
    assign inst_pcaddu12i   = op_31_26_d[6'h07] & ~inst[25];                                                    // read -     , write rd
    assign inst_slli_w      = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];      // read rj    , write rd
    assign inst_sltu        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];      // read rj, rk, write rd
    assign inst_sra_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];      // read rj, rk, write rd
    assign inst_srli_w      = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];      // read rj    , write rd
    assign inst_st_b        = op_31_26_d[6'h0a] & op_25_22_d[4'h4];                                             // read rj, rd, write -
    assign inst_st_w        = op_31_26_d[6'h0a] & op_25_22_d[4'h6];                                             // read rj, rd, write -
    assign inst_sub_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];      // read rj, rk, write rd
    assign inst_xor         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];      // read rj, rk, write rd

    // ***********************************************************
    // * REG ADDR GEN
    // ***********************************************************

    assign rd               = inst[ 4: 0];
    assign rj               = inst[ 9: 5];
    assign rk               = inst[14:10];

    assign dst_is_r1        = inst_bl;
    assign gr_we            = (dest != 5'b0) & ~(inst_st_w | inst_bne | inst_beq | inst_st_b | inst_bltu | inst_b);//通用寄存器写使能
    assign rf_we            = gr_we & valid;//寄存器文件写使能

    assign dest             = {5{dst_is_r1}} & 5'b1 | {5{~dst_is_r1}} & rd;

    assign rf_raddr1        = rj;
    assign rf_raddr2        = src_reg_is_rd ? rd : rk;

    // ***********************************************************
    // * IMM GEN 生成立即数
    // ***********************************************************

    assign need_ui5         = inst_srli_w | inst_slli_w;
    assign need_si12        = inst_addi_w | inst_ld_w | inst_st_w | inst_st_b | inst_ld_b;
    assign need_si16        = inst_bne | inst_beq | inst_bltu | inst_jirl;
    assign need_si20        = inst_lu12i_w | inst_pcaddu12i;
    assign need_si26        = inst_b | inst_bl;
    assign need_ui12        = inst_ori | inst_andi;

    assign i12              = inst[21:10];
    assign i20              = inst[24: 5];
    assign i16              = inst[25:10];
    assign i26              = {inst[9:0], inst[25:10]};
    assign ui5              = inst[14:10];

    assign imm              =
        {32{src2_is_4}} & 32'h4                      |
        {32{need_si20}} & {i20[19:0], 12'b0}         |
        {32{need_ui5}}  & {27'b0, ui5[4:0]}          |
        {32{need_si12}} & {{20{i12[11]}}, i12[11:0]} |
        {32{need_ui12}} & {20'b0, i12[11:0]}         ;

    // ***********************************************************
    // * ALU OP GEN
    // ***********************************************************

    assign alu_op[ 0]       = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w | inst_pcaddu12i | inst_st_b | inst_ld_b | inst_jirl | inst_bl;
    assign alu_op[ 1]       = inst_sub_w;
    assign alu_op[ 2]       = inst_sltu;
    assign alu_op[ 3]       = inst_andi | inst_and;
    assign alu_op[ 4]       = inst_or | inst_ori;
    assign alu_op[ 5]       = inst_xor;
    assign alu_op[ 6]       = inst_slli_w;
    assign alu_op[ 7]       = inst_srli_w;
    assign alu_op[ 8]       = inst_sra_w;
    assign alu_op[ 9]       = inst_lu12i_w;
    assign alu_op[10]       = inst_mul_w;
    assign alu_op[11]       = inst_mod_w;
    assign alu_op[12]       = inst_mod_wu;

    assign alu_src1  = src1_is_pc ? pc : rj_value;
    assign alu_src2  = src2_is_imm ? imm : rkd_value;

    // ***********************************************************
    // * OPRAND GEN
    // ***********************************************************

    assign src2_is_4        = inst_jirl | inst_bl;
    assign src_reg_is_rd    = inst_bne | inst_beq | inst_bltu | inst_st_w | inst_st_b;
    assign res_from_mem     = inst_ld_w | inst_ld_b;
    assign src1_is_pc       = inst_pcaddu12i | inst_jirl | inst_bl;
    assign src2_is_imm      = inst_addi_w | inst_ld_w | inst_st_w | inst_lu12i_w | inst_pcaddu12i | inst_ori | inst_andi | inst_st_b | inst_ld_b | inst_srli_w | inst_slli_w | inst_jirl | inst_bl;

    // ***********************************************************
    // * BRANCH GEN
    // ***********************************************************

    assign br_offs          =   {32{need_si26}}  & {{ 4{i26[25]}}, i26[25:0], 2'b0}  |
                                {32{~need_si26}} & {{14{i16[15]}}, i16[15:0], 2'b0}  ;
    assign jirl_offs        = {{14{i16[15]}}, i16[15:0], 2'b0};

    assign rj_lt_rkd_s = $signed(rj_value) < $signed(rkd_value);
    assign rj_lt_rkd_u = $unsigned(rj_value) < $unsigned(rkd_value);
    assign rj_eq_rd = (rj_value == rkd_value);

    assign branch_flag = valid ? (inst_bne & ~rj_eq_rd) | (inst_beq & rj_eq_rd) | (inst_bltu & rj_lt_rkd_u) | inst_jirl | inst_b | inst_bl : 0;
    
    assign branch_addr = inst_bne | inst_beq | inst_bltu | inst_b | inst_bl ? pc + br_offs :
                        inst_jirl ? rj_value + jirl_offs : 0;

    assign nextpc      = (dst_conflict | stall_next_stage | stall_if) ? pc : branch_flag ? branch_addr : pc + 32'h4;

    // ***********************************************************
    // * MEM GEN
    // ***********************************************************

    assign mem_we          = inst_st_w | inst_st_b;//写入内存的指令
    assign mem_load        = inst_ld_w | inst_ld_b;//从内存取操作数的指令

    assign data_sram_be    = inst_st_w | inst_ld_w ? {4{data_sram_ce}} : inst_st_b | inst_ld_b ? {3'b0,data_sram_ce} : 0;
    assign data_sram_wdata = rkd_value;
    assign data_sram_we    = mem_we & valid & ~dst_conflict;
    assign data_sram_oe    = res_from_mem;
    assign data_sram_ce    = res_from_mem | data_sram_we;//存储器片选信号，ld或st指令

    // ***********************************************************
    // * FORWARD AND REG WRITE GEN
    // ***********************************************************

    assign addr1_is_eq[0] = ((reg_waddr_out & {5{reg_we_out}} ) == rf_raddr1);//要写入的寄存器和要读取的寄存器是同一个，发生冲突
    assign addr1_is_eq[1] = ((reg_waddr_mem & {5{reg_we_mem}} ) == rf_raddr1);//ex
    assign addr1_is_eq[2] = ((reg_waddr_wb  & {5{reg_we_wb}}  ) == rf_raddr1);
    assign addr2_is_eq[0] = ((reg_waddr_out & {5{reg_we_out}} ) == rf_raddr2);//要写入的寄存器和要读取的寄存器是同一个，发生冲突
    assign addr2_is_eq[1] = ((reg_waddr_mem & {5{reg_we_mem}} ) == rf_raddr2);//ex
    assign addr2_is_eq[2] = ((reg_waddr_wb  & {5{reg_we_wb}}  ) == rf_raddr2);

    always@(*)begin
        if(dst1_conflict & mem_load_mem & addr1_is_eq[1])//mem_load_mem来自MEM模块
            rj_value = mem_result;//mem
        else if(dst1_conflict & addr1_is_eq[0])
            rj_value = reg_wdata_ex;//ex，alu_result
        else if(dst1_conflict & addr1_is_eq[1])
            rj_value = reg_wdata_mem;//ex，可能是alu_result
        else if(dst1_conflict & addr1_is_eq[2])
            rj_value = reg_wdata_wb;//wb,final_result，可能是alu_result,也可能是mem_result
        else 
            rj_value = rf_rdata1;
    end

    always@(*)begin
        if(dst2_conflict & mem_load_mem & addr2_is_eq[1])//mem_load_mem来自MEM模块
            rkd_value = mem_result;//mem
        else if(dst2_conflict & addr2_is_eq[0])
            rkd_value = reg_wdata_ex;//ex
        else if(dst2_conflict & addr2_is_eq[1])
            rkd_value = reg_wdata_mem;//ex
        else if(dst2_conflict & addr2_is_eq[2])
            rkd_value = reg_wdata_wb;//wb
        else 
            rkd_value = rf_rdata2;
    end

    assign inst_no_rf1 = inst_lu12i_w | inst_pcaddu12i | inst_b | inst_bl;
    assign inst_no_rf2 = inst_addi_w | inst_ld_w | inst_lu12i_w | inst_pcaddu12i | inst_ori | inst_andi | inst_ld_b | inst_srli_w | inst_slli_w | inst_jirl | inst_b | inst_bl;

    assign dst1_conflict = ~inst_no_rf1 & (rf_raddr1 != 5'b0) & |addr1_is_eq;
    assign dst2_conflict = ~inst_no_rf2 & (rf_raddr2 != 5'b0) & |addr2_is_eq;
    assign dst_conflict = ~valid ? 1'b0 : (dst1_conflict | dst2_conflict) & mem_load_out ;
    
    assign stall_current_stage = valid & dst_conflict | stall_if;
    
    regfile u_regfile(
            .clk    ( clk          ),

            .raddr1 ( rf_raddr1    ),
            .rdata1 ( rf_rdata1    ),
            .raddr2 ( rf_raddr2    ),
            .rdata2 ( rf_rdata2    ),

            .we     ( reg_we_wb    ),//来自MEM模块
            .waddr  ( reg_waddr_wb ),//来自MEM模块
            .wdata  ( reg_wdata_wb ) //来自MEM模块
        );

    IDEX IDEX(
        .clk                 ( clk                 ),
        .reset               ( reset               ),
        .stall_current_stage ( stall_current_stage ),
        .stall_next_stage    ( stall_next_stage    ),

        .alu_src1            ( alu_src1            ),
        .alu_src2            ( alu_src2            ),
        .alu_op              ( alu_op              ),
        .dest                ( dest                ),
        .rf_we               ( rf_we               ),
        .data_sram_wdata     ( data_sram_wdata     ),
        .data_sram_be        ( data_sram_be        ),
        .data_sram_ce        ( data_sram_ce        ),
        .data_sram_oe        ( data_sram_oe        ),
        .data_sram_we        ( data_sram_we        ),
        .valid               ( valid               ),
        .mem_load            ( mem_load            ),
        //output
        .operand1_out        ( operand1_out        ),
        .operand2_out        ( operand2_out        ),
        .alu_op_out          ( alu_op_out          ),
        .reg_waddr_out       ( reg_waddr_out       ),
        .reg_we_out          ( reg_we_out          ),
        .data_sram_wdata_out ( data_ram_wdata_out  ),//给ex
        .data_sram_be_out    ( data_ram_be_out     ),
        .data_sram_ce_out    ( data_ram_ce_out     ),
        .data_sram_oe_out    ( data_ram_oe_out     ),
        .data_sram_we_out    ( data_ram_we_out     ),
        .valid_out           ( valid_out           ),
        .mem_load_out        ( mem_load_out        )
    );


endmodule