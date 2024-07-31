module Core(
    input  wire         clk,
    input  wire         reset,

    output wire [31: 0] inst_ram_vaddr, //�����ַ������MMU
    input  wire [31: 0] inst_ram_rdata, //����MMU������ָ��

    output wire [31: 0] data_ram_vaddr, //�����ַ������MMU
    input  wire [31: 0] data_ram_rdata, //����MMU
    output wire [31: 0] data_ram_wdata, //����MMU

    output wire [ 3: 0] data_ram_be,    
    output wire         data_ram_ce,
    output wire         data_ram_oe,
    output wire         data_ram_we,    //����4���źž�����MMU

    input  wire         wait_mem        //����MMU
);

    reg          valid;
    wire [31: 0] pc, pc_ex;//pc_ex��ʱ����
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
     IFģ����������pcֵ������ָ���Ƿ������IDģ��
     */
    IF IF(                     //�����ж�ģ��
        .clk                 ( clk            ),
        .reset               ( reset          ),
        .valid               ( valid          ),//��IDģ�鹲��

        .branch_flag         ( branch_flag    ),//����IDģ��
        .branch_addr         ( branch_addr    ),//����IDģ�飬��ת��ַ���ڱ�ģ������ʱû��

        .pc                  ( pc             ),//�����IDģ��
        .nextpc              ( nextpc         ),//����IDģ��
        .inst_addr           ( inst_ram_vaddr ),//�����MMU������nextpc
        .inst                ( inst_ram_rdata ),//����MMU

        .stall_next_stage    ( stall_id       ),//����IDģ��
        .wait_mem            ( wait_mem       ),//����MMU���Ƿ�ȴ��ڴ棿
        
        // buf
        .inst_out            ( inst           ),//�����IDģ��
        .valid_out           ( valid_id       ),//��������������������
        .stall_current_stage ( stall_if       ) //�����IDģ�飬assign stall_current_stage = wait_mem;

    );

    ID ID(
        .clk                 ( clk               ),
        .reset               ( reset             ),
        .valid               ( valid             ),//��IFģ�鹲��

        .stall_current_stage ( stall_id          ),//�����IFģ��
        .stall_next_stage    ( stall_ex          ),//����EXģ��

        .branch_flag         ( branch_flag       ),//�����IFģ��
        .branch_addr         ( branch_addr       ),//�����IFģ��

        .pc                  ( pc                ),//����IFģ��
        .inst                ( inst              ),//����IFģ�飬32λָ����

        .operand1_out        ( operand1          ),//�����EXģ�飬��Ϊalu_src1
        .operand2_out        ( operand2          ),//�����EXģ�飬��Ϊalu_src2
        .alu_op_out          ( alu_op            ),//�����EXģ�飬��Ϊalu_op

        .reg_waddr_out       ( reg_waddr_ex      ),//�����EXģ�飬��ΪҪд��ļĴ�������
        .reg_we_out          ( reg_we_ex         ),//�����EXģ�飬��Ϊ�Ĵ�����дʹ��
        .reg_wdata_ex        ( reg_wdata_ex      ),//����EXģ��

        .reg_waddr_mem       ( reg_waddr_mem     ),//����EXģ��
        .reg_we_mem          ( reg_we_mem        ),//����EXģ��
        .reg_wdata_mem       ( reg_wdata_mem     ),//����EXģ��

        .reg_waddr_wb        ( reg_waddr_wb      ),//����MEMģ��
        .reg_we_wb           ( reg_we_wb         ),//����MEMģ��
        .reg_wdata_wb        ( reg_wdata_wb      ),//����WBģ��

        .mem_load_out        ( mem_load_ex       ),//ģ���ڲ�ʹ��

        .mem_load_mem        ( mem_load_mem      ),//����MEMģ��
        .mem_result          ( mem_result        ),//����MEMģ��

        .valid_out           ( valid_ex          ),//�����EXģ��

        .data_ram_wdata_out  ( data_ram_wdata_ex ),//�����EXģ��
        .data_ram_be_out     ( data_ram_be_ex    ),
        .data_ram_ce_out     ( data_ram_ce_ex    ),
        .data_ram_oe_out     ( data_ram_oe_ex    ),
        .data_ram_we_out     ( data_ram_we_ex    ),//����4���źž������EXģ��
        .stall_if            ( stall_if          ),//����IFģ��
        
        .nextpc              ( nextpc            ) //�����IFģ��

    );

    EX EX(
        .clk                ( clk               ),
        .reset              ( reset             ),
        .valid              ( valid_ex          ),//����IDģ��valid_out

        .stall_next_stage   ( stall_mem         ),//����MEMģ��stall_current_stage
        .req_from_exe       ( stall_ex          ),//�����ID��stall_next_stage

        .alu_op             ( alu_op            ),//����IDģ��
        .alu_src1           ( operand1          ),//����IDģ��
        .alu_src2           ( operand2          ),//����IDģ��
        .alu_result         ( alu_result        ),//������������������

        .data_sram_be_ex    ( data_ram_be_ex    ),
        .data_sram_we_ex    ( data_ram_we_ex    ),
        .data_sram_oe_ex    ( data_ram_oe_ex    ),
        .data_sram_ce_ex    ( data_ram_ce_ex    ),//����4���źž�����IDģ��
        .data_sram_wdata_ex ( data_ram_wdata_ex ),//����IDģ��
        
        .data_sram_be       ( data_ram_be       ),//�����MMU��MEMģ��
        .data_sram_we       ( data_ram_we       ),//�����MMUģ��
        .data_sram_wdata    ( data_ram_wdata    ),//�����MMUģ��
        .data_sram_addr     ( data_ram_vaddr    ),//�����MMU��MEMģ��
        .data_sram_oe       ( data_ram_oe       ),//�����MMUģ��
        .data_sram_ce       ( data_ram_ce       ),//�����MMUģ��

        .reg_waddr          ( reg_waddr_ex      ),//����IDģ��
        .reg_we             ( reg_we_ex         ),//����IDģ��
        .reg_wdata          ( reg_wdata_ex      ),//�����IDģ��
        .reg_waddr_out      ( reg_waddr_mem     ),//�����MEM��IDģ��
        .reg_we_out         ( reg_we_mem        ),//�����MEM��IDģ��
        .reg_wdata_out      ( reg_wdata_mem     ),//�����MEM��IDģ��

        .valid_out          ( valid_mem         ) //�����MEMģ��
    );

    wire mem_load_wb;

    MEM MEM(
        .clk                 ( clk            ),
        .reset               ( reset          ),
        .valid               ( valid_mem      ),//����EXģ��

        .stall_next_stage    ( 0              ),//�ӵ�
        .stall_current_stage ( stall_mem      ),//�����EXģ��

        .data_ram_be         ( data_ram_be    ),//����EXģ��
        .data_ram_rdata      ( data_ram_rdata ),//����MMU

        .mem_result          ( mem_result     ),//�����IDģ��
        .mem_result_out      ( mem_result_wb  ),//�����WBģ��
        .res_from_mem        ( mem_load_mem   ),//�����IDģ��
        .res_from_mem_out    ( mem_load_wb    ),//�����WBģ��

        .reg_waddr           ( reg_waddr_mem  ),//����EXģ��
        .reg_we              ( reg_we_mem     ),//����EXģ��
        .reg_wdata           ( reg_wdata_mem  ),//����EXģ��

        .reg_waddr_out       ( reg_waddr_wb   ),//�����IDģ��
        .reg_we_out          ( reg_we_wb      ),//�����IDģ��
        .reg_wdata_out       ( alu_result_wb  ),//�����WBģ��
        .data_ram_addr       ( data_ram_vaddr ) //����EXģ��
    );

    WB WB(
        .res_from_mem  ( mem_load_wb   ),//����MEMģ�飬��·ѡ�������ж�����
        .mem_result    ( mem_result_wb ),//����MEMģ��
        .alu_result    ( alu_result_wb ),//����MEMģ��
        .final_result  ( reg_wdata_wb  ) //�����IDģ��
    );
endmodule