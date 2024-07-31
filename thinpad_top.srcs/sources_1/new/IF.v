module IF(
    input  wire         clk                ,
    input  wire         reset              ,
    input  wire         valid              , 

    input  wire         branch_flag        ,//从ID模块来
    input  wire [31: 0] branch_addr        ,//跳转地址，暂时没用

    output reg  [31: 0] pc                 ,//本模块生成，输出给ID模块

    input  wire [31: 0] nextpc             ,//下一条指令地址
    output wire [31: 0] inst_addr          ,

    input  wire [31: 0] inst               ,//来自MMU
    output wire [31: 0] inst_out           ,//指令输出内容
    // buffer
    output wire         stall_current_stage,
    input  wire         stall_next_stage   ,
    output wire         valid_out          ,//用处不详
    input  wire         wait_mem            //来自MMU，是否等待内存？
);

    always @(posedge clk) begin
        if (reset) 
            pc <= 32'h7FFF_FFFC;//初始pc
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