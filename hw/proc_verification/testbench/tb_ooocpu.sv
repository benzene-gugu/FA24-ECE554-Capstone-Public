import m_rv32::*;
module tb_ooocpu();
    logic rst_n, clk, peri_r, peri_w;
    logic [27:0] peri_addr;
    logic [31:0] peri_rdata, peri_wdata;
    logic TX, RX;

    top_proc iCPU(.rst_n, .clk, .peri_r, .peri_w, .peri_addr, .peri_wdata, .peri_rdata);

    //===================
    //peripheral mux
    //===================
    logic w_led, iocs_n, iorw_n, uartioaddr;
	logic vram_we;
	logic [5:0] vram_wrdata, vram_wdata, vga_rdata;
	logic [18:0] vga_raddr;
	logic [31:0] uart_datain, uart_dataout;
    always_comb begin
        w_led = 0;

		uart_datain = 'x;
		iocs_n = 1;
		iorw_n = ~peri_w; //don't care before cs is asserted
		uartioaddr = 1;

		vram_we = 0;
		vram_wdata = 0;

		peri_rdata = 0;
		//if(peri_r | peri_w)
		case(peri_addr) //default to read data
			//========
			//LED
			//========
			MMAP_LED:
				w_led = peri_w;
			//========
			//UART
			//========
			MMAP_UARTCTL: begin// cs only when addr is right and there is r/w
				iocs_n = ~(peri_r | peri_w);
				uartioaddr = 1;
				if(peri_w) uart_datain = peri_wdata;
				else peri_rdata = uart_dataout;
			end
			MMAP_UART_TR: begin //cs only when addr is right and there is r/w
				iocs_n = ~(peri_r | peri_w);
				uartioaddr = 0;
				if(peri_w) uart_datain = peri_wdata;
				else peri_rdata = uart_dataout;
			end
			
			default: begin
			//========
			//VGA
			//========
				if(peri_addr >= MMAP_FRAMEBF && peri_addr < MMAP_FRAMEBF+SIZE_FRAMEBF)begin
					vram_we = peri_w;
					if(peri_w)
						vram_wdata = peri_wdata;
					else
						peri_rdata = vram_wrdata;
				end
			end
		endcase
    end

    peripheral_spart iUART(.clk, .rst_n, .iocs_n, .iorw_n, .tx_q_full(), .rx_q_empty(), .ioaddr(uartioaddr), .dataout(uart_dataout), .datain(uart_datain), .TX, .RX);
    peripheral_videoMem iVRAM(.clk(clk),.we(vram_we),.waddr(peri_addr[20:2]),.wdata(vram_wdata), .wrdata(vram_wrdata), .raddr(vga_raddr),.rdata(vga_rdata));

    initial begin
        rst_n = 0;
        clk = 0;
        repeat(3)
            @(negedge clk);
        rst_n = 1;
        repeat(100000)
            @(negedge clk);
        $stop();
    end

    always
        #2 clk = ~clk;
endmodule