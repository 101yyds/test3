module dff #(
    parameter WIDTH = 1
)(
    input  wire                clk,
    input  wire                rst,
    input  wire                stall_current_stage,
    input  wire                stall_next_stage,
    input  wire [WIDTH - 1: 0] in,
    output reg  [WIDTH - 1: 0] out
);

    always @(posedge clk ) begin
        if(rst)
            out <= 0;
        else if(stall_current_stage & ~stall_next_stage)
            out <= 0;
        else if(~stall_current_stage & ~stall_next_stage)
            out <= in;
    end
    
endmodule