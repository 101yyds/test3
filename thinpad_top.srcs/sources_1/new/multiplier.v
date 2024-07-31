module mul_module(
    input  wire         clk         ,
    input  wire         rst         ,
    input  wire         valid       ,
    input  wire [31: 0] src1        ,
    input  wire [31: 0] src2        ,
    output wire [31: 0] product     ,
    output wire         req_from_mul
);

    reg  [31: 0] src1_latch, src2_latch;
    reg  [ 3: 0] cnt;
    reg  [ 2: 0] current_state;
    wire [ 2: 0] next_state;

    parameter IDLE = 3'b001, MUL = 3'b010, DONE = 3'b100;

    always @(posedge clk ) begin
        if(rst)
            src1_latch <= 0;
        else if(valid)
            src1_latch <= src1;
    end

    always @(posedge clk ) begin
        if(rst)
            src2_latch <= 0;
        else if(valid)
            src2_latch <= src2;
    end

    always @(posedge clk ) begin
        if(rst)
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    assign next_state = {3{current_state[0] && valid}} & MUL 
                    | {3{current_state[0] && ~valid}} & IDLE 
                    | {3{current_state[1] && (cnt==5)}} & DONE 
                    | {3{current_state[1] && (cnt!=5)}} & MUL
                    | {3{current_state[2] && valid}} & MUL
                    | {3{current_state[2] && ~valid}} & IDLE;

    always @(posedge clk ) begin
        if(rst || current_state==DONE)
            cnt <= 0;
        else if(current_state==MUL)
            cnt <= cnt + 1;
    end

    assign req_from_mul = current_state[1];

    mult_32 mult(
        .CLK ( clk        ),
        .A   ( src1_latch ),
        .B   ( src2_latch ),
        .P   ( product    )
    );

endmodule