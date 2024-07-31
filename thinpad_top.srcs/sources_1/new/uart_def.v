`define CLK 33
`define T (1000*113.4375/`CLK)

`define UART_START \
    #3000 rxd = 0;

`define UART_END \
    #`T rxd = 1;

`define UART_0 \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0;

`define UART_1 \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0;

`define UART_2 \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0;

`define UART_3 \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0;

`define UART_4 \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0;

`define UART_5 \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0;

`define UART_6 \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0;

`define UART_7 \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0;

`define UART_8 \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1;

`define UART_9 \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1;

`define UART_A \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1;

`define UART_B \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1;

`define UART_C \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1;

`define UART_D \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1;

`define UART_E \
    #`T \
    rxd = 0; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1;

`define UART_F \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1; \
    #`T \
    rxd = 1;