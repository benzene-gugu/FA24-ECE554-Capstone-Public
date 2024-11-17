import m_rv32::*;
import SDRAM_params::*; // Import the SDRAM parameters
module tb_topcpu();
    logic clk, rst_n, clk100m;

    wire [USER_ADDRESS_WIDTH-1:0] addr_SDRAM; // Address signal for the SDRAM
    logic re_SDRAM; // Read enable signal for the SDRAM
    logic we_SDRAM; // Write enable signal for the SDRAM
    wire [15:0] data_read_SDRAM; // Data read from the SDRAM
    logic [15:0] data_write_SDRAM; // Data write to the SDRAM
    wire valid_SDRAM; // Valid signal indicating that the read/write data is valid
    wire done_SDRAM; // Done signal indicating that the first write is complete

    wire CLK; // Clock signal
    wire [CHIP_ADDRESS_WIDTH-1:0] SA; // Chip select address signal
    wire [BANK_ADDRESS_WIDTH-1:0] BA; // Bank address signal
    wire CS_N; // Chip select signal
    wire CKE; // Clock enable signal
    wire RAS_N; // Row address strobe signal
    wire CAS_N; // Column address strobe signal
    wire WE_N; // Write enable signal
    wire [DQM_WIDTH-1:0] DQM; // Data mask signal
    wire [DATA_WIDTH-1:0] DQ; // Data signal

    // sdram_direct_interface sdram_ctrl_intf(.clk(clk100m), .re(re_SDRAM), .we(we_SDRAM), .addr(addr_SDRAM), .data_read(data_read_SDRAM), 
    //                 .data_write(data_write_SDRAM), .valid(valid_SDRAM), .done(done_SDRAM), 
    //                 .CLK, .SA, .BA, .CS_N, .CKE, .RAS_N, .CAS_N, .WE_N, .DQM, .DQ);
    top_proc iCPU(.rst_n, .clk, .peri_r(), .peri_w(), .peri_addr(), .peri_wdata(), .peri_rdata(), .led());
                //   .clk100m, .addr_SDRAM, .re_SDRAM, .we_SDRAM, .data_read_SDRAM, .data_write_SDRAM, .valid_SDRAM, .done_SDRAM);

    sdram_interface iSDRAM(.clk(clk100m), .re(re_SDRAM), .we(we_SDRAM), .addr(addr_SDRAM), .data_read(data_read_SDRAM), 
	                       .data_write(data_write_SDRAM), .valid(valid_SDRAM), .done(done_SDRAM), 
						   .CLK(CLK), .SA, .BA, .CS_N, .CKE, .RAS_N, .CAS_N, .WE_N, .DQM, .DQ);
    mt48lc32m16a2 sdram_model(.BA0(BA[0]), .BA1(BA[1]),
                             .DQMH(DQM[1]), .DQML(DQM[0]),
                             .DQ0(DQ[0]), .DQ1(DQ[1]), .DQ2(DQ[2]), .DQ3(DQ[3]), .DQ4(DQ[4]), .DQ5(DQ[5]), .DQ6(DQ[6]), .DQ7(DQ[7]),
                             .DQ8(DQ[8]), .DQ9(DQ[9]), .DQ10(DQ[10]), .DQ11(DQ[11]), .DQ12(DQ[12]), .DQ13(DQ[13]), .DQ14(DQ[14]), .DQ15(DQ[15]),
                             .CLK, .CKE,
                             .A0(SA[0]), .A1(SA[1]), .A2(SA[2]), .A3(SA[3]), .A4(SA[4]), .A5(SA[5]), .A6(SA[6]), .A7(SA[7]), .A8(SA[8]), .A9(SA[9]), .A10(SA[10]), .A11(SA[11]), .A12(SA[12]),
                             .RASNeg(RAS_N), .CASNeg(CAS_N), .WENeg(WE_N), .CSNeg(CS_N));

    integer n_half_cycles = 0;
    integer fail = 0;

    initial begin
        rst_n = 0;
        clk = 0;
        clk100m = 0;
        repeat(3) @(negedge clk);
        rst_n = 1;
    end

    always begin
        #5  clk100m = ~clk100m; //100MHz clk
    end
    always begin
        #10 clk = ~clk; //50MHz clk
        n_half_cycles += 1;
        if(n_half_cycles >= 1e6)begin
            $display("TIME OUT!");
            $finish();
        end
        if(iCPU.iFetch.halt) begin
            $display("DONE.");
            if(fail === 0)
                $display("PASS.");
            $finish();
            //check x10=0d, x17=93d
        end
    end

    always @(iCPU.cdb)
        if((iCPU.iDec.regs.RS[10].sreg.tag_match & iCPU.iDec.regs.RS[10].sreg.renamed & iCPU.iDec.regs.RS[10].sreg.w_data !== 0) && (iCPU.iDec.regs.RS[17].sreg.regdata === 93)) begin
            $display("FAIL. TEST: %d, at %d", iCPU.iDec.regs.RS[10].sreg.w_data[31:1], n_half_cycles); 
            fail = 1;
        end
endmodule
