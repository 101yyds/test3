module Core(
    input  wire         clk,
    input  wire         reset,

    output wire [31: 0] inst_ram_vaddr, //虚拟地址，传给MMU
    input  wire [31: 0] inst_ram_rdata, //来自MMU，就是指令

    output wire [31: 0] data_ram_vaddr, //虚拟地址，传给MMU
    input  wire [31: 0] data_ram_rdata, //来自MMU
    output wire [31: 0] data_ram_wdata, //传给MMU

    output wire [ 3: 0] data_ram_be,    
    output wire         data_ram_ce,
    output wire         data_ram_oe,
    output wire         data_ram_we,    //以上4个信号均传给MMU

    input  wire         wait_mem        //来自MMU
);

    reg          valid;
    wire [31: 0] pc, pc_ex;//pc_ex暂时不用
    wire         branch_flag;
    wire [31: 0] branch_addr;
    wire         stall_id, stall_ex, stall_mem;
    wire [31: 0] inst;

    wire [31: 0] operand1;
    wire [31: 0] operand2;

    wire [12: 0] alu_op;

    wire [ 4: 0] reg_waddr_ex;
    wire         reg_we_ex;
    wire [31: 0] reg_wdata_ex ;

    wire [ 4: 0] reg_waddr_mem;
    wire         reg_we_mem   ;
    wire [31: 0] reg_wdata_mem;

    wire [ 4: 0] reg_waddr_wb ;
    wire         reg_we_wb    ;
    wire [31: 0] reg_wdata_wb ;

    wire         mem_load_ex;
    wire         mem_load_mem;
    wire [31: 0] mem_result;
    wire [31: 0] mem_result_wb;
    wire         valid_ex, valid_id, valid_mem;

    wire [31: 0] data_ram_wdata_ex;
    wire [ 3: 0] data_ram_be_ex;
    wire         data_ram_ce_ex;
    wire         data_ram_oe_ex;
    wire         data_ram_we_ex;

    wire [31: 0] alu_result, alu_result_wb;
    wire [31: 0] nextpc;
    wire         stall_if;



    always @(posedge clk) begin
        if (reset)
            valid <= 1'b0;
        else
            valid <= 1'b1;
    end
    /*
     IF模块用于生成pc值，决定指令是否输出给ID模块
     */
    IF IF(                     //条件判断模块
        .clk                 ( clk            ),
        .reset               ( reset          ),
        .valid               ( valid          ),//与ID模块共用

        .branch_flag         ( branch_flag    ),//来自ID模块
        .branch_addr         ( branch_addr    ),//来自ID模块，跳转地址，在本模块中暂时没用

        .pc                  ( pc             ),//输出给ID模块
        .nextpc              ( nextpc         ),//来自ID模块
        .inst_addr           ( inst_ram_vaddr ),//输出给MMU，等于nextpc
        .inst                ( inst_ram_rdata ),//来自MMU

        .stall_next_stage    ( stall_id       ),//来自ID模块
        .wait_mem            ( wait_mem       ),//来自MMU，是否等待内存？
        
        // buf
        .inst_out            ( inst           ),//输出给ID模块
        .valid_out           ( valid_id       ),//待定？？？？？？？？
        .stall_current_stage ( stall_if       ) //输出给ID模块，assign stall_current_stage = wait_mem;

    );

    ID ID(
        .clk                 ( clk               ),
        .reset               ( reset             ),
        .valid               ( valid             ),//与IF模块共用

        .stall_current_stage ( stall_id          ),//输出给IF模块
        .stall_next_stage    ( stall_ex          ),//来自EX模块

        .branch_flag         ( branch_flag       ),//输出给IF模块
        .branch_addr         ( branch_addr       ),//输出给IF模块

        .pc                  ( pc                ),//来自IF模块
        .inst                ( inst              ),//来自IF模块，32位指令码

        .operand1_out        ( operand1          ),//输出给EX模块，作为alu_src1
        .operand2_out        ( operand2          ),//输出给EX模块，作为alu_src2
        .alu_op_out          ( alu_op            ),//输出给EX模块，作为alu_op

        .reg_waddr_out       ( reg_waddr_ex      ),//输出给EX模块，作为要写入的寄存器代号
        .reg_we_out          ( reg_we_ex         ),//输出给EX模块，作为寄存器的写使能
        .reg_wdata_ex        ( reg_wdata_ex      ),//来自EX模块

        .reg_waddr_mem       ( reg_waddr_mem     ),//来自EX模块
        .reg_we_mem          ( reg_we_mem        ),//来自EX模块
        .reg_wdata_mem       ( reg_wdata_mem     ),//来自EX模块

        .reg_waddr_wb        ( reg_waddr_wb      ),//来自MEM模块
        .reg_we_wb           ( reg_we_wb         ),//来自MEM模块
        .reg_wdata_wb        ( reg_wdata_wb      ),//来自WB模块

        .mem_load_out        ( mem_load_ex       ),//模块内部使用

        .mem_load_mem        ( mem_load_mem      ),//来自MEM模块
        .mem_result          ( mem_result        ),//来自MEM模块

        .valid_out           ( valid_ex          ),//输出给EX模块

        .data_ram_wdata_out  ( data_ram_wdata_ex ),//输出给EX模块
        .data_ram_be_out     ( data_ram_be_ex    ),
        .data_ram_ce_out     ( data_ram_ce_ex    ),
        .data_ram_oe_out     ( data_ram_oe_ex    ),
        .data_ram_we_out     ( data_ram_we_ex    ),//以上4个信号均输出给EX模块
        .stall_if            ( stall_if          ),//来自IF模块
        
        .nextpc              ( nextpc            ) //输出给IF模块

    );

    EX EX(
        .clk                ( clk               ),
        .reset              ( reset             ),
        .valid              ( valid_ex          ),//来自ID模块valid_out

        .stall_next_stage   ( stall_mem         ),//来自MEM模块stall_current_stage
        .req_from_exe       ( stall_ex          ),//输出给ID的stall_next_stage

        .alu_op             ( alu_op            ),//来自ID模块
        .alu_src1           ( operand1          ),//来自ID模块
        .alu_src2           ( operand2          ),//来自ID模块
        .alu_result         ( alu_result        ),//待定？？？？？？？

        .data_sram_be_ex    ( data_ram_be_ex    ),
        .data_sram_we_ex    ( data_ram_we_ex    ),
        .data_sram_oe_ex    ( data_ram_oe_ex    ),
        .data_sram_ce_ex    ( data_ram_ce_ex    ),//以上4个信号均来自ID模块
        .data_sram_wdata_ex ( data_ram_wdata_ex ),//来自ID模块
        
        .data_sram_be       ( data_ram_be       ),//输出给MMU，MEM模块
        .data_sram_we       ( data_ram_we       ),//输出给MMU模块
        .data_sram_wdata    ( data_ram_wdata    ),//输出给MMU模块
        .data_sram_addr     ( data_ram_vaddr    ),//输出给MMU，MEM模块
        .data_sram_oe       ( data_ram_oe       ),//输出给MMU模块
        .data_sram_ce       ( data_ram_ce       ),//输出给MMU模块

        .reg_waddr          ( reg_waddr_ex      ),//来自ID模块
        .reg_we             ( reg_we_ex         ),//来自ID模块
        .reg_wdata          ( reg_wdata_ex      ),//输出给ID模块
        .reg_waddr_out      ( reg_waddr_mem     ),//输出给MEM，ID模块
        .reg_we_out         ( reg_we_mem        ),//输出给MEM，ID模块
        .reg_wdata_out      ( reg_wdata_mem     ),//输出给MEM，ID模块

        .valid_out          ( valid_mem         ) //输出给MEM模块
    );

    wire mem_load_wb;

    MEM MEM(
        .clk                 ( clk            ),
        .reset               ( reset          ),
        .valid               ( valid_mem      ),//来自EX模块

        .stall_next_stage    ( 0              ),//接地
        .stall_current_stage ( stall_mem      ),//输出给EX模块

        .data_ram_be         ( data_ram_be    ),//来自EX模块
        .data_ram_rdata      ( data_ram_rdata ),//来自MMU

        .mem_result          ( mem_result     ),//输出给ID模块
        .mem_result_out      ( mem_result_wb  ),//输出给WB模块
        .res_from_mem        ( mem_load_mem   ),//输出给ID模块
        .res_from_mem_out    ( mem_load_wb    ),//输出给WB模块

        .reg_waddr           ( reg_waddr_mem  ),//来自EX模块
        .reg_we              ( reg_we_mem     ),//来自EX模块
        .reg_wdata           ( reg_wdata_mem  ),//来自EX模块

        .reg_waddr_out       ( reg_waddr_wb   ),//输出给ID模块
        .reg_we_out          ( reg_we_wb      ),//输出给ID模块
        .reg_wdata_out       ( alu_result_wb  ),//输出给WB模块
        .data_ram_addr       ( data_ram_vaddr ) //来自EX模块
    );

    WB WB(
        .res_from_mem  ( mem_load_wb   ),//来自MEM模块，多路选择器的判断条件
        .mem_result    ( mem_result_wb ),//来自MEM模块
        .alu_result    ( alu_result_wb ),//来自MEM模块
        .final_result  ( reg_wdata_wb  ) //输出给ID模块
    );
endmodule