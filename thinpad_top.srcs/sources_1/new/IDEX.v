module IDEX(
    input  wire         clk                ,
    input  wire         reset              ,
    input  wire         stall_current_stage,
    input  wire         stall_next_stage   ,
    
    input  wire [31: 0] alu_src1           ,
    input  wire [31: 0] alu_src2           ,
    input  wire [12: 0] alu_op             ,
    input  wire [ 4: 0] dest               ,
    input  wire         rf_we              ,
    input  wire [31: 0] data_sram_wdata    ,
    input  wire [ 3: 0] data_sram_be       ,
    input  wire         data_sram_ce       ,
    input  wire         data_sram_oe       ,
    input  wire         data_sram_we       ,
    input  wire         valid              ,
    input  wire         mem_load           ,

    output wire [31: 0] operand1_out       ,
    output wire [31: 0] operand2_out       ,
    output wire [12: 0] alu_op_out         ,
    output wire [ 4: 0] reg_waddr_out      ,
    output wire         reg_we_out         ,
    output wire [31: 0] data_sram_wdata_out,
    output wire [ 3: 0] data_sram_be_out   ,
    output wire         data_sram_ce_out   ,
    output wire         data_sram_oe_out   ,
    output wire         data_sram_we_out   ,
    output wire         valid_out          ,
    output wire         mem_load_out       
);
    /*
     dff.v Ö´ĞĞÂß¼­
         always @(posedge clk ) begin
        if(rst)
            out <= 0;
        else if(stall_current_stage & ~stall_next_stage) //1 0
            out <= 0;
        else if(~stall_current_stage & ~stall_next_stage)//0 0
            out <= in;
    end*/

    dff#(32) operand1_dff(
        clk, 
        reset, 
        stall_current_stage, 
        stall_next_stage,
        alu_src1, 
        operand1_out
    );

    dff#(32) operand2_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        alu_src2, 
        operand2_out
    );

    dff#(13) alu_op_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        alu_op, 
        alu_op_out
    );

    dff#(5) reg_waddr_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        dest, 
        reg_waddr_out
    );

    dff#(1) reg_we_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        rf_we, 
        reg_we_out
    );

    dff#(32) data_ram_wdata_dff(
        clk, 
        reset, 
        stall_current_stage, 
        stall_next_stage,
        data_sram_wdata, 
        data_sram_wdata_out
    );

    dff#(4) data_ram_be_dff(
        clk, 
        reset, 
        stall_current_stage, 
        stall_next_stage,
        data_sram_be, 
        data_sram_be_out
    );

    dff#(1) data_ram_ce_dff(
        clk, reset, stall_current_stage, stall_next_stage,
        data_sram_ce, data_sram_ce_out
    );

    dff#(1) data_ram_oe_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        data_sram_oe, 
        data_sram_oe_out
    );

    dff#(1) data_ram_we_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        data_sram_we, 
        data_sram_we_out
    );

    dff#(1) valid_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        valid, 
        valid_out
    );

    dff#(1) mem_load_dff(
        clk, reset, 
        stall_current_stage, 
        stall_next_stage,
        mem_load, 
        mem_load_out
    );

endmodule