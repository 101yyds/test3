module FIFO(
    input  wire         clk   ,
    input  wire         reset ,
    input  wire         wvalid,
    input  wire [ 7: 0] wdata ,
    input  wire         rvalid,
    output wire [ 7: 0] rdata ,
    output wire         full  ,
    output wire         empty
);

//    0                                       1
//    0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5 
//  +---------------------------------------------------------------+
//  | A | B | C | D | E | F | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
//  +---------------------------------------------------------------+
//    ^   ^                                                          
//    |   |                                                          
//    p   q                                                          
//
    reg  [ 7: 0] fifo [63: 0];
    reg  [ 7: 0] fifo_ptr_p, fifo_ptr_q, fifo_cnt;
    wire [ 7: 0] cur_data;

    assign full = (fifo_cnt == 63);
    assign empty = (fifo_cnt == 0);

    assign rdata =  rvalid & wvalid ? wdata             : 
                    rvalid          ? fifo[fifo_ptr_p]  :
                                                            8'bz ;

    always @(posedge clk )begin
        if(reset) begin
            fifo_cnt   <= 0;
            fifo_ptr_p <= 0;
            fifo_ptr_q <= 0;
        end
        else if(rvalid & wvalid) begin
            fifo_cnt   <= fifo_cnt;
            fifo_ptr_p <= fifo_ptr_p + 1;
            fifo_ptr_q <= fifo_ptr_q + 1;
            fifo[fifo_ptr_q] <= wdata;
        end
        else if(rvalid & ~wvalid & ~empty) begin
            fifo_cnt   <= fifo_cnt - 1;
            fifo_ptr_p <= fifo_ptr_p + 1;
            fifo_ptr_q <= fifo_ptr_q;
        end
        else if(~rvalid & wvalid & ~full) begin
            fifo_cnt   <= fifo_cnt + 1;
            fifo_ptr_p <= fifo_ptr_p;
            fifo_ptr_q <= fifo_ptr_q + 1;
            fifo[fifo_ptr_q] <= wdata;
        end
        else  begin
            fifo_cnt   <= fifo_cnt;
            fifo_ptr_p <= fifo_ptr_p;
            fifo_ptr_q <= fifo_ptr_q;
        end
    end

    


endmodule