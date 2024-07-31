module WB(
    input  wire         res_from_mem,
    input  wire [31: 0] mem_result,
    input  wire [31: 0] alu_result,
    output wire [31: 0] final_result
    );

    assign final_result = res_from_mem ? mem_result : alu_result;

endmodule