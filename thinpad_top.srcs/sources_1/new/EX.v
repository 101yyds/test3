module EX(
    input  wire         clk                ,
    input  wire         reset              ,
    input  wire         valid              ,

    input  wire         stall_next_stage   ,

    input  wire [ 3: 0] data_sram_be_ex    ,
    input  wire         data_sram_we_ex    ,
    input  wire         data_sram_oe_ex    ,
    input  wire         data_sram_ce_ex    ,
    input  wire [31: 0] data_sram_wdata_ex ,//要写入存储器的数据
    input  wire [12: 0] alu_op             ,//来自ID模块

    output wire         req_from_exe       ,
    output wire [31: 0] alu_result         ,
    input  wire [31: 0] alu_src1           ,
    input  wire [31: 0] alu_src2           ,

    output wire [ 3: 0] data_sram_be       ,
    output wire         data_sram_we       ,
    output wire [31: 0] data_sram_wdata    ,
    output wire [31: 0] data_sram_addr     ,
    output wire         data_sram_oe       ,
    output wire         data_sram_ce       ,

    input  wire [ 4: 0] reg_waddr          ,
    input  wire         reg_we             ,
    output wire [31: 0] reg_wdata          ,
    
    output wire [ 4: 0] reg_waddr_out      ,
    output wire         reg_we_out         ,
    output wire [31: 0] reg_wdata_out      ,
    output wire         valid_out

);

    wire [ 1: 0] res_end;

    assign res_end = alu_result[1:0];

    reg  [ 3: 0] data_ram_be;
    reg  [31: 0] data_ram_wdata;

    assign reg_wdata = alu_result;

    alu u_alu(
            .clk           ( clk            ),
            .rst           ( reset          ),

            .alu_op        ( alu_op         ),
            .alu_src1      ( alu_src1       ),
            .alu_src2      ( alu_src2       ),
            .alu_result    ( alu_result     ),
            .stall_alu     ( req_from_exe   )
        );

    always@(*)begin
        case ({data_sram_be_ex, res_end}) // synopsys parallel_case
            6'b0001_00: begin
                data_ram_be = 4'b0001 & {4{data_sram_ce_ex}};
                data_ram_wdata = {24'b0,data_sram_wdata_ex[7:0]};
            end
            6'b0001_01: begin
                data_ram_be = 4'b0010 & {4{data_sram_ce_ex}};
                data_ram_wdata = {16'b0,data_sram_wdata_ex[7:0],8'b0};
            end
            6'b0001_10: begin
                data_ram_be = 4'b0100 & {4{data_sram_ce_ex}};
                data_ram_wdata = {8'b0,data_sram_wdata_ex[7:0],16'b0};
            end
            6'b0001_11: begin
                data_ram_be = 4'b1000 & {4{data_sram_ce_ex}};
                data_ram_wdata = {data_sram_wdata_ex[7:0],24'b0};
            end
            default:  begin
                data_ram_be = 4'b1111 & {4{data_sram_ce_ex}};
                data_ram_wdata = data_sram_wdata_ex;
            end
        endcase
    end
    /*
     dff.v 执行逻辑
         always @(posedge clk ) begin
        if(rst)
            out <= 0;
        else if(stall_current_stage & ~stall_next_stage) //1 0
            out <= 0;
        else if(~stall_current_stage & ~stall_next_stage)//0 0
            out <= in;
    end*/

    dff#(4) data_sram_be_dff(
        clk, reset, req_from_exe, stall_next_stage,
        data_ram_be, data_sram_be
    );

    dff#(1) data_sram_we_dff(
        clk, reset, req_from_exe, stall_next_stage,
        data_sram_we_ex, data_sram_we
    );

    dff#(1) data_sram_oe_dff(
        clk, reset, req_from_exe, stall_next_stage,
        data_sram_oe_ex, data_sram_oe
    );

    dff#(1) data_sram_ce_dff(
        clk, reset, req_from_exe, stall_next_stage,
        data_sram_ce_ex, data_sram_ce
    );

    dff#(32) data_sram_wdata_dff(
        clk, reset, req_from_exe, stall_next_stage,
        data_sram_wdata_ex, data_sram_wdata
    );

    dff#(32) data_sram_addr_dff(
        clk, reset, req_from_exe, stall_next_stage,
        {alu_result[31:2],2'b00}, data_sram_addr
    );

    dff#(5) reg_waddr_dff(
        clk, reset, req_from_exe, stall_next_stage,
        reg_waddr, reg_waddr_out
    );

    dff#(1) reg_we_dff(
        clk, reset, req_from_exe, stall_next_stage,
        reg_we, reg_we_out
    );

    dff#(32) reg_wdata_dff(
        clk, reset, req_from_exe, stall_next_stage,
        reg_wdata, reg_wdata_out
    );

    dff#(1) valid_dff(
        clk, reset, req_from_exe, stall_next_stage,
        valid, valid_out
    );
endmodule
