module fifotb();


reg          clk   ;
reg          reset ;

reg          wvalid;
reg  [ 7: 0] wdata ;

reg          rvalid;
wire [ 7: 0] rdata ;

wire         full  ;

reg          w;

initial begin
    clk = 0;
    reset = 1;
    #100
    reset = 0;
    w=1;
    #350
    w=0;
    #350
    $finish();
end

always #5 clk = ~clk;

always @(posedge clk ) begin
    if(reset)begin
        wvalid <= 0;
        wdata <= 0;
        rvalid <= 0;
    end else if(w)begin 
        wvalid <= 1;
        wdata <= $urandom();
        rvalid <= 1;
    end else begin
        wvalid <= 0;
        wdata <= 0;
        rvalid <= 1;
    end
end


FIFO FIFO(
    .clk    ( clk    ),
    .reset  ( reset  ),
    .wvalid ( wvalid ),
    .wdata  ( wdata  ),
    .rvalid ( rvalid ),
    .rdata  ( rdata  ),
    .full   (        )
);


endmodule