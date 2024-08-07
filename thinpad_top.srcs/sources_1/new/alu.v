module alu(
        input  wire         clk       ,
        input  wire         rst       ,
        input  wire [12: 0] alu_op    ,
        input  wire [31: 0] alu_src1  ,
        input  wire [31: 0] alu_src2  ,
        output wire [31: 0] alu_result,
        output wire         stall_alu
    );

    wire op_add   ; // add operation
    wire op_sub   ; // sub operation
    wire op_sltu  ; // unsigned compared and set less than
    wire op_and   ; // bitwise and
    wire op_or    ; // bitwise or
    wire op_xor   ; // bitwise xor
    wire op_sll   ; // logic left shift
    wire op_srl   ; // logic right shift
    wire op_sra   ; // arithmetic right shift
    wire op_lui   ; // Load Upper Immediate
    wire op_mul   ; // multiply operation
    wire op_mod_s ; // mod operation
    wire op_mod_u ; // unsigned mode operation

    wire stall_div;
    wire stall_mul;

    // control code decomposition
    assign op_add   = alu_op[ 0];
    assign op_sub   = alu_op[ 1];
    assign op_sltu  = alu_op[ 2];
    assign op_and   = alu_op[ 3];
    assign op_or    = alu_op[ 4];
    assign op_xor   = alu_op[ 5];
    assign op_sll   = alu_op[ 6];
    assign op_srl   = alu_op[ 7];
    assign op_sra   = alu_op[ 8];
    assign op_lui   = alu_op[ 9];
    assign op_mul   = alu_op[10];
    assign op_mod_s = alu_op[11];
    assign op_mod_u = alu_op[12];

    wire [31: 0] add_sub_result;
    wire [31: 0] sltu_result;
    wire [31: 0] and_result;
    wire [31: 0] or_result;
    wire [31: 0] xor_result;
    wire [31: 0] lui_result;
    wire [31: 0] sll_result;
    wire [63: 0] sr64_result;
    wire [31: 0] sr_result;
    (*use_dsp="yes"*) 
    wire [31: 0] mul_result_s;
    wire [31: 0] mod_result;

    assign stall_alu = stall_div;
    // assign stall_alu = stall_div | stall_mul;

    // 32-bit adder
    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire        adder_cin;
    wire [31:0] adder_result;
    wire        adder_cout;

    assign adder_a   = alu_src1;
    assign adder_b   = (op_sub | op_sltu) ? ~alu_src2 : alu_src2;  
    assign adder_cin = (op_sub | op_sltu) ? 1'b1      : 1'b0;
    assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

    // ADD, SUB result
    assign add_sub_result = adder_result;

    // MUL result
    // mul_module mul_module(
    //     .clk          ( clk          ),
    //     .rst          ( rst          ),
    //     .valid        ( op_mul       ),
    //     .src1         ( alu_src1     ),
    //     .src2         ( alu_src2     ),
    //     .product      ( mul_result_s ),
    //     .req_from_mul ( stall_mul    )
    // );

    assign mul_result_s = $signed(alu_src1) * $signed(alu_src2);

    // SLTU result
    assign sltu_result[31:1] = 31'b0;
    assign sltu_result[0]    = ~adder_cout;

    // bitwise operation
    assign and_result = alu_src1 & alu_src2;
    assign or_result  = alu_src1 | alu_src2; 
    assign xor_result = alu_src1 ^ alu_src2;
    assign lui_result = alu_src2;

    // SLL result
    assign sll_result = alu_src1 << alu_src2[4:0];   

    // SRL, SRA result
    assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; 

    assign sr_result   = sr64_result[31:0]; 

    // final result mux
    assign alu_result = 
             ({32{op_add | op_sub    }} & add_sub_result)
           | ({32{op_sltu            }} & sltu_result)
           | ({32{op_and             }} & and_result)
           | ({32{op_or              }} & or_result)
           | ({32{op_xor             }} & xor_result)
           | ({32{op_lui             }} & lui_result)
           | ({32{op_sll             }} & sll_result)
           | ({32{op_srl | op_sra    }} & sr_result)
           | ({32{op_mul             }} & mul_result_s);

endmodule
