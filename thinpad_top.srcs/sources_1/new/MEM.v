module MEM(
    input  wire         clk                 ,
    input  wire         reset               ,
    input  wire         valid               ,

    input  wire         stall_next_stage    ,
    output wire         stall_current_stage ,//输出给EX模块

    input  wire [ 3: 0] data_ram_be         ,//来自EX模块
    input  wire [31: 0] data_ram_addr       ,
    input  wire [31: 0] data_ram_rdata      ,//来自MMU

    output reg  [31: 0] mem_result          ,//输出给ID模块
    output wire [31: 0] mem_result_out      ,//输出给WB模块
    output wire         res_from_mem_out    ,//输出给WB模块

    input  wire [ 4: 0] reg_waddr           ,//来自EX模块
    input  wire [31: 0] reg_wdata           ,//EX
    input  wire         reg_we              ,//EX

    output wire [ 4: 0] reg_waddr_out       ,//输出给ID
    output wire [31: 0] reg_wdata_out       ,//输出给WB
    output wire         reg_we_out          ,//输出给ID模块


    output wire         res_from_mem      

);

    assign stall_current_stage = 0;

    assign res_from_mem = |data_ram_be;

    // successful fetched data
    always@(*)begin
        case (data_ram_be) 
            4'b0000: 
                mem_result = 'h0;
            4'b0001: 
                mem_result = {{24{data_ram_rdata[ 7]}},data_ram_rdata[ 7: 0]};
            4'b0010: 
                mem_result = {{24{data_ram_rdata[15]}},data_ram_rdata[15: 8]};
            4'b0100: 
                mem_result = {{24{data_ram_rdata[23]}},data_ram_rdata[23:16]};
            4'b1000: 
                mem_result = {{24{data_ram_rdata[31]}},data_ram_rdata[31:24]};
            default: 
                mem_result = data_ram_rdata;
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

    dff#(32) data_ram_rdata_dff(
        clk, reset, stall_current_stage, stall_next_stage,
        mem_result, mem_result_out
    );

    dff#(32) reg_wdata_dff(
        clk, reset, stall_current_stage, stall_next_stage,
        reg_wdata, reg_wdata_out
    );

    dff#(5) reg_waddr_dff(
        clk, reset, stall_current_stage, stall_next_stage,
        reg_waddr, reg_waddr_out
    );

    dff#(1) reg_we_dff(
        clk, reset, stall_current_stage, stall_next_stage,
        reg_we, reg_we_out
    );

    dff#(1) res_from_mem_dff(
        clk, reset, stall_current_stage, stall_next_stage,
        res_from_mem, res_from_mem_out
    );

endmodule