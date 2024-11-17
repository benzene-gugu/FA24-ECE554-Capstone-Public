module peripheral_led(rst_n, clk, LED, wdata, w_led);
    input logic rst_n, clk, w_led;
    input logic [9:0] wdata;
    output logic [9:0] LED;


    reg [9:0] LED_reg;

    assign LED = LED_reg;

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            LED_reg <= 0;
        else if(w_led) //update on w_led signal
            LED_reg <= wdata[9:0];
endmodule