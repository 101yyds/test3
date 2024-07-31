module div_module(
    input  wire         clk,
    input  wire         rst,
    input  wire         div_signed,
    input  wire         div_unsigned,
    input  wire [31: 0] div_src1,
    input  wire [31: 0] div_src2,
    output wire [31: 0] div_res,
    output wire [31: 0] mod_res,
    output wire         req_from_div
);
    
    localparam  IDLE    = 'h1,
                RUNNING = 'h2,
                DONE    = 'h4;

    reg  [31: 0] src1_locker, src2_locker;
    reg  [ 7: 0] div_current_state, div_next_state;
    reg          div_op_locker;

    wire         div_valid;
    wire         done;
    wire         running;

    assign div_valid    = (div_current_state==IDLE) && (div_next_state==RUNNING);
    assign req_from_div = (div_current_state==IDLE) && (div_next_state==RUNNING) || (div_current_state==RUNNING);

    always @(*) begin
        if(rst)begin
            div_next_state = IDLE;
        end else begin
            case (div_current_state)
                IDLE:
                    div_next_state = div_signed | div_unsigned ? RUNNING : IDLE;
                RUNNING:
                    div_next_state = done ? DONE : RUNNING;
                DONE: 
                    div_next_state = IDLE;
                default: 
                    div_next_state = IDLE;
            endcase
        end
    end

    always@(posedge clk )begin
        if(rst)begin
            div_current_state <= IDLE;
        end else begin
            div_current_state <= div_next_state;
        end
    end

    always @(*) begin
        if (div_signed | div_unsigned) begin
            src1_locker <= div_src1;
            src2_locker <= div_src2;
        end
    end

    always @(*) begin
        if(rst) begin
            div_op_locker = 'd0;
        end
        else if(div_valid) begin
            div_op_locker = div_signed;
        end
    end

    div_unit div_unit(
                 .clk           ( clk           ),
                 .rst           ( rst           ),
                 .op            ( div_op_locker ),
                 .dividend      ( src1_locker   ),
                 .divisor       ( src2_locker   ),
                 .start         ( div_valid     ),
                 .running       ( running       ),
                 .remainder_out ( mod_res       ),
                 .quotient_out  ( div_res       ),
                 .done          ( done          )
             );
endmodule //div_module
