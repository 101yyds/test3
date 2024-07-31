module IFID (
    input  wire         clk                ,
    input  wire         reset              ,
    input  wire         stall_current_stage,
    input  wire         stall_next_stage   ,

    input  wire [31: 0] inst               ,
    input  wire         valid              ,
    
    output wire [31: 0] inst_out           ,
    output wire         valid_out
    
);
    /*
     dff.v ִ���߼�
         always @(posedge clk ) begin
        if(rst)
            out <= 0;
        else if(stall_current_stage & ~stall_next_stage) //1 0
            out <= 0;
        else if(~stall_current_stage & ~stall_next_stage)//0 0
            out <= in;
    end*/
    dff#(32) inst_dff(
        clk, 
        reset,
        stall_current_stage, 
        stall_next_stage,
        inst,    //in,32λ��ָ��
        inst_out //out��32λ
    );

    dff#(1) valid_dff(
        clk, 
        reset, 
        stall_current_stage, 
        stall_next_stage,
        valid,    //in��1λ
        valid_out //out��1λ
    );

endmodule