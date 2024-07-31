module uart_transmitter #(
    parameter   ClkFrequency = 100_000_000,
                Buad         = 9600
)(
    input  wire         clk        ,
    input  wire         reset      ,
    output wire         tx         ,
    input  wire         uart_wvalid,
    input  wire [ 7: 0] uart_wdata ,
    output wire         tx_busy
);

    localparam  IDLE = 1,       // nothing to send, empty
                START = 2,      // start
                TRANSMIT = 4;   // trasnmitting, but not full

    reg  [ 2: 0] current_state;
    wire [ 2: 0] next_state;
    wire         full;
    wire         empty;
    wire         busy;

    wire [ 7: 0] rdata_to_sent;
    wire         rvalid;

    assign tx_busy = full;

    always @(posedge clk ) begin
        if(reset)
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    assign next_state = {3{current_state[0] & ~uart_wvalid}} & IDLE 
                    |   {3{current_state[0] & uart_wvalid}} & START
                    |   {3{current_state[1]}} & TRANSMIT
                    |   {3{current_state[2] & busy}} & TRANSMIT
                    |   {3{current_state[2] & ~busy & ~empty}} & START
                    |   {3{current_state[2] & ~busy & empty}} & IDLE;


    assign rvalid = (current_state==START);

    FIFO FIFO_TX(
        .clk     ( clk           ),
        .reset   ( reset         ),
        
        .wvalid  ( uart_wvalid   ),
        .wdata   ( uart_wdata    ),

        .rvalid  ( rvalid        ),
        .rdata   ( rdata_to_sent ),

        .full    ( full          ),
        .empty   ( empty         )
    );

`ifdef SIMULATION
    always @(posedge clk ) begin
        if(rvalid)
            $display("T: %c, HEX: %h", rdata_to_sent, rdata_to_sent);
    end
`endif

    async_transmitter#(
        .ClkFrequency ( ClkFrequency ),
        .Baud         ( Buad         )
    ) async_transmitter(
        .clk       ( clk           ),
        .TxD_start ( rvalid        ),
        .TxD_data  ( rdata_to_sent ),
        .TxD       ( tx            ),
        .TxD_busy  ( busy          )
    );


endmodule