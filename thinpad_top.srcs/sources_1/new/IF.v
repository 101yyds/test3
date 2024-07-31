module IF(
    input  wire         clk                ,
    input  wire         reset              ,
    input  wire         valid              , 

    input  wire         branch_flag        ,//��IDģ����
    input  wire [31: 0] branch_addr        ,//��ת��ַ����ʱû��

    output reg  [31: 0] pc                 ,//��ģ�����ɣ������IDģ��

    input  wire [31: 0] nextpc             ,//��һ��ָ���ַ
    output wire [31: 0] inst_addr          ,

    input  wire [31: 0] inst               ,//����MMU
    output wire [31: 0] inst_out           ,//ָ���������
    // buffer
    output wire         stall_current_stage,
    input  wire         stall_next_stage   ,
    output wire         valid_out          ,//�ô�����
    input  wire         wait_mem            //����MMU���Ƿ�ȴ��ڴ棿
);

    always @(posedge clk) begin
        if (reset) 
            pc <= 32'h7FFF_FFFC;//��ʼpc
        else 
            pc <= nextpc;
    end

    assign inst_addr = nextpc;
    assign stall_current_stage = wait_mem;

    IFID IFID(
        .clk                 ( clk                 ),
        .reset               ( reset               ),
        .stall_current_stage ( stall_current_stage ),
        .stall_next_stage    ( stall_next_stage    ),
        .inst                ( inst                ),
        .inst_out            ( inst_out            ),
        .valid               ( valid               ),
        .valid_out           ( valid_out           )
    );

endmodule