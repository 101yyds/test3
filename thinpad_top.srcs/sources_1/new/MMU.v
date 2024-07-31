//
// - - - - - - - - - |--------------|               |--------------|
// 0xFFFF_FFFF       |    kseg3     |               |    kseg3     |
//                   |    (512M)    |               |    (512M)    |
// 0xE000_0000       |              |               |              |
// - - - - - - - - - |--------------|-------------->|--------------|
// 0xDFFF_FFFF       |    kseg2     |               |    kseg2     |
//                   |    (512M)    |               |    (512M)    |
// 0xC000_0000       |              |               |              |
// - - - - - - - - - |--------------|-------------->|--------------|
// 0xBFFF_FFFF       |    kseg1     |               |              |
//                   |    (512M)    |               |              |
// 0xA000_0000       |              |               |   reversed   |
// - - - - - - - - - |--------------|----           |              |
// 0x9FFF_FFFF       |    kseg0     |    \          |              |
//                   |    (512M)    |     \         |              |
// 0x8000_0000       |              |      \        |              |
// - - - - - - - - - |--------------|-      \       |--------------|
// 0x7FFF_FFFF       |              | \      \      |    ksueg     |
//                   |              |  \      \     |    (2G)      |
//                   |              |   \      \    |              |
//                   |    ksueg     |   |       \   |              |
//                   |    (2G)      |   |        |  |              |
//                   |              |    \       |  |              |
//                   |              |     \      |  |- - - - - - - |
//                   |              |      \     \  | kseg0/kseg1  |
// 0x0000_0000       |              |       \     \ |   (512M)     |
// - - - - - - - - - |--------------|        ------>|--------------|

//  0xBFD0_03F8: serial RW
//  0xBFD0_03FC, bit 0: 1 when serial is idle
//  0xBFD0_03FC, bit 1: 1 when serial received

// `define SIMULATION
`define BAUD_RATE 9600
`define CLK_FREQUENCY 47_000_000

module MMU(
    input  wire         clk, //cpuʱ��
    input  wire         reset,//��λ
    // from cpu
    input  wire [31: 0] inst_ram_vaddr, //�ں˴�����ָ���ַ
    output wire [31: 0] inst_ram_rdata, //�����ںˣ�����ָ��

    input  wire [31: 0] data_ram_vaddr, //�ں˴��������ݵ�ַ
    output wire [31: 0] data_ram_rdata, //�����ں�
    input  wire [31: 0] data_ram_wdata, //�ں˴�����Ҫд��洢��������
    input  wire [ 3: 0] data_ram_be,    //����ʹ�ܣ��ڶ�·���������������豸�У�����ѡ���Ƿ����ݴ��豸����������ϡ��� BE �ź���Чʱ�����ݱ������������ϴ��䣻���������������ϱ���ֹ��
    input  wire         data_ram_ce,    //оƬʹ�ܣ��ڼ��ɵ�·����оƬ�����������û��������оƬ��ģ�顣�� CE �ź���Чʱ��оƬ���ڹ���״̬���� CE �ź���Чʱ��оƬ���ܽ���͹���ģʽ����ȫֹͣ������
    input  wire         data_ram_oe,    //���ʹ�ܣ������豸������Ƿ���Ч���� OE �ź���Чʱ���豸��������Ա����䵽�ⲿ�������豸���������ֹ���߸���̬��
    input  wire         data_ram_we,    //дʹ�ܣ��ڴ洢�����߼Ĵ����У����ڿ���д������Ľ��С��� WE �ź���Чʱ����������д��洢�����߼Ĵ������� WE �ź���Чʱ��д���������ֹ��

    // to base ram �������������
    inout  wire [31: 0] base_ram_data,
    output wire [19: 0] base_ram_addr,
    output wire [ 3: 0] base_ram_be_n,
    output wire         base_ram_ce_n,
    output wire         base_ram_oe_n,
    output wire         base_ram_we_n,
    // to ext ram �������������
    inout  wire [31: 0] ext_ram_data,
    output wire [19: 0] ext_ram_addr,
    output wire [ 3: 0] ext_ram_be_n,
    output wire         ext_ram_ce_n,
    output wire         ext_ram_oe_n,
    output wire         ext_ram_we_n,

    output wire         stall_req,      //��ͣ����

    input  wire         rx,             //���ڽ��ն�
    output wire         tx              //���������
);
    //            3           2                          
    //            1           1                       2 0
    //     vaddr: xxxx_xxxx_xx00_0000_0000_0000_0000_00xx
    // where 0 is bit actually mapped to base ram or ext ram

    wire [19: 0] inst_ram_addr, data_ram_addr;//ָ����ݴ洢����ַ
    wire         base_seg, ext_seg, uart_rw_seg, uart_stat_seg;//�ж�ӳ��Ĵ洢��
    wire         uart_seg;                    
    wire [ 7: 0] uart_wdata;                  //���ں˴���������ȡ��8λ
    wire         uart_wvalid;                 //
    wire         uart_rvalid;
    wire [ 7: 0] uart_rdata;
    reg  [ 7: 0] uart_rdata_lock;
    reg  [ 7: 0] uart_stat;
    reg          uart_rvalid_lock;
    wire         di_seg;

    wire         tx_busy;
    wire         RxD_data_ready;
    wire         RxD_data_clear;

    assign inst_ram_addr = inst_ram_vaddr[21:2];
    assign data_ram_addr = data_ram_vaddr[21:2];

    // base - read only, INST RAM
    // from 0x8000_0000 to 0x800F_FFFF, this seg is mapped to a read-only seg. MONITOR_CODE_seg
    // from 0x8010_0000 to 0x803F_FFFF, this seg is mapped to a read-only seg. USER_CODE_seg
    assign base_seg = (inst_ram_vaddr >= 32'h8000_0000) && (inst_ram_vaddr <= 32'h803F_FFFF);//ӳ�䵽base_ram����δ���

    // ext - read and write, DATA RAM
    // from 0x8040_0000 to 0x807E_FFFF, this seg is mapped to a read and write seg. USER_DATA_seg
    // from 0x807F_0000 to 0x807F_FFFF, this seg is mapped to a read and write seg. MONITOR_DATA_seg
    assign ext_seg    = (data_ram_vaddr >= 32'h8040_0000) && (data_ram_vaddr <= 32'h807F_FFFF);//ӳ�䵽base_ram����δ���

    assign di_seg           = (data_ram_vaddr >= 32'h8000_0000) && (data_ram_vaddr <= 32'h803F_FFFF) && data_ram_ce && |data_ram_be && (data_ram_oe || data_ram_we);//ӳ�䵽BaseRam
    assign stall_req        = di_seg;

    // this seg is mapped to an UART. UART DATA AND STATE
    assign uart_rw_seg      = (data_ram_vaddr == 32'hBFD0_03F8);
    assign uart_stat_seg    = (data_ram_vaddr == 32'hBFD0_03FC);
    assign uart_seg         = uart_rw_seg | uart_stat_seg;//��uart_segΪ�ߵ�ƽ����di_segΪ�͵�ƽ

    assign uart_wdata       = data_ram_wdata[7:0];
    assign uart_wvalid      = uart_seg & data_ram_ce & data_ram_we;
    assign uart_rvalid      = uart_seg & data_ram_ce & data_ram_oe;

    // INST RAM
    assign base_ram_addr = di_seg ? data_ram_addr : inst_ram_addr;
    assign base_ram_be_n = di_seg ? ~data_ram_be : 4'b0;
    assign base_ram_ce_n = di_seg ? ~data_ram_ce : 1'b0;
    assign base_ram_oe_n = di_seg ? ~data_ram_oe : 1'b0;
    assign base_ram_we_n = di_seg ? ~data_ram_we : 1'b1;//???�Ƿ�Ӧ��Ϊ1'b0
    
    assign base_ram_data = di_seg ? data_ram_we ? data_ram_wdata : 32'bz : 32'bz;

    assign inst_ram_rdata = base_ram_data;//ָ��洢��Ҫ�õ�ָ���в�����

    // DATA RAM
    // Write when the address is not falled in the uart seg
    assign ext_ram_data = data_ram_ce & data_ram_we & ~uart_seg ? data_ram_wdata : 32'bz;
    // Don't care the addr
    assign ext_ram_addr = data_ram_addr;
    // Disable ram when the address falls in the uart seg
    assign ext_ram_be_n = uart_seg ? 4'b1111 : ~data_ram_be;
    assign ext_ram_ce_n = uart_seg ? 1'b1 : ~data_ram_ce;
    assign ext_ram_oe_n = uart_seg ? 1'b1 : ~data_ram_oe;
    assign ext_ram_we_n = uart_seg ? 1'b1 : ~data_ram_we;

    assign data_ram_rdata = di_seg ? base_ram_data : 
                            uart_stat_seg ? {24'b0, uart_stat} : 
                            uart_seg ? {24'b0, uart_rdata_lock} : ext_ram_data;

    always @(posedge clk ) begin
        if(reset)
            uart_rvalid_lock <= 0;
        else if(RxD_data_clear)
            uart_rvalid_lock <= 0;
        else if(RxD_data_ready)
            uart_rvalid_lock <= 1;
    end


    assign RxD_data_clear = uart_rvalid_lock & uart_rw_seg;

    always @(posedge clk ) begin
        if(reset)
            uart_rdata_lock <= 0;
        else if(RxD_data_ready)
            uart_rdata_lock <= uart_rdata;
    end

    always @(posedge clk ) begin
        if(reset)
            uart_stat <= 8'b0000_0001;
        else
            uart_stat <= {6'b0, uart_rvalid_lock, ~tx_busy};
    end

    uart_transmitter#(
        .ClkFrequency ( `CLK_FREQUENCY ),
        .Buad         ( `BAUD_RATE     )
    ) uart_trasnmitter(
        .clk            ( clk         ),
        .reset          ( reset       ),
        .tx             ( tx          ),//ȫ�����
        .uart_wvalid    ( uart_wvalid ),//
        .uart_wdata     ( uart_wdata  ),//data_ram_wdata[7:0]
        .tx_busy        ( tx_busy     )//
    );

`ifdef SIMULATION
    always @(posedge clk ) begin
        if(RxD_data_clear)
            $display("R: HEX: %h", uart_rdata_lock);
    end
`endif

    async_receiver#(
        .ClkFrequency ( `CLK_FREQUENCY ),
        .Baud         ( `BAUD_RATE     )
    ) async_receiver(
        .clk            ( clk            ),
        .RxD            ( rx             ),//ȫ������
        .RxD_data_ready ( RxD_data_ready ),//��������ж�����
        .RxD_clear      ( RxD_data_clear ),//����
        .RxD_data       ( uart_rdata     ) //���
    );

endmodule

// This module designed to arise an assertion error when simulation marco
// is defined
`ifdef SIMULATION
module ASSERTION_ERROR ();
endmodule
`endif 