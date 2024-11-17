import m_rv32::*;
//
//cannot use block memory, enables register renaming
/*
on neg edge
1, read data/tag, bypassing if necessary
2, writedata & tag
3, write tag
*/
/**
 * @brief register for reservation station
 *
 * This module implements a single-register storage element with write and read functionality.
 *
 * @param clk            : Clock input for the module
 * @param rst_n          : Active-low asynchronous reset input
 * @param wrt_tag_en     : Write enable signal for the register from fetching stage (tag only)
 * @param wrt_tag        : the tag to write
 * @param w_data_src     : Source of the data from execution unit
 * @param w_data         : data to write
 * @param r_data         : Output data from the register
 * @param d_sel          : 0 for data, 1 for srouce of the data at the moment
 */
module one_reg(clk, rst_n, wrt_tag_en, wrt_tag, w_data_src, w_data, r_data, d_sel);
    /*
    */
    input logic clk, rst_n, wrt_tag_en;
    input fu_addr_t wrt_tag;
    input fu_addr_t w_data_src;
    input logic [31:0] w_data;
    output logic [31:0] r_data;
    output logic d_sel;

    logic [31:0] regdata;
    fu_addr_t tag; //0: data
    logic renamed, tag_match;
    assign renamed = |tag;
    assign tag_match = tag === w_data_src;

    always_ff @(negedge clk, negedge rst_n) begin
        if(!rst_n) begin
            tag <= FU_NULL;
            regdata <= 0;
            r_data <= 0;
            d_sel <= 0;
        end
        else begin
            //reading data
            {d_sel, r_data} <= ~(renamed) ? {1'b0, regdata} : ( //tag = 0, real data
                                (tag_match) ? {1'b0, w_data} : ( //bypassing write data
                                {1'b1, 29'b0, tag} //renamed reg
                                ));
            //writedata, write tag only
            if(wrt_tag_en) //renamed again, no need to write any real data, only tag
                tag <= wrt_tag;
            // no new tag, write real data if there is any
            else if(renamed & tag_match) begin// write new data and clear tag
                tag <= FU_NULL;
                regdata <= w_data;
            end
        end
    end
endmodule

/**
 * @brief register file for out-of-order execution
 * 
 * check the graph
 * Note: Write data is done by CDB, write tag is by #EU(wrt_src), wrt_sel and w_en
 *       CDB write can not happen at the same clock as write tag request (write tag has the priority)
 *       Read is done every cycle, can be bypassed if CDB write at the same clock (matching tag)
 *       Special reg is never passed to real reg
 *       reset to all 0s
 *
 * @param clk            : Clock input for the module
 * @param rst_n          : Active-low asynchronous reset input
 * @param re1_sel        : read port 1 addr
 * @param re2_sel        : Read port 2 addr
 * @param wrt_sel        : Write to addr
 * @param wrt_src        : Source of the data to be written
 * @param w_en           : Write enable signal
 * @param r1_data        : Output data from read port 1
 * @param r1_d_sel       : Output data from port 1 type (0 is the read data)
 * @param r2_data        : Output data from read port 2
 * @param r2_d_sel       : Output data from port 2 type (0 is the read data)
 * @param cdb            : Common data bus input
 */
module RegFile_ooo(clk, rst_n, re1_sel, re2_sel, wrt_sel, wrt_src, w_en, r1_data, r1_d_sel, r2_data, r2_d_sel, cdb);
    parameter XLEN = 32;

    input  logic clk, rst_n, w_en; 
    input  logic [4:0] re1_sel, re2_sel, wrt_sel;
    input  fu_addr_t wrt_src;
    input  CDB_t cdb;
    output  logic r1_d_sel, r2_d_sel;
    output logic [XLEN-1:0] r1_data, r2_data;

    logic [31:0] wrt_tag_en;
    logic [31:0] d_sel_reg;
    logic [XLEN-1:0] r_data_reg [31:0];

    //0 reg lock
    assign r_data_reg[0] = 32'b0;
    assign d_sel_reg[0] = 0;

    assign wrt_tag_en = ({31'd0, w_en} << wrt_sel);

    //except 0 reg
	genvar i;
	generate
    for(i = 1; i <= 31; ++i)begin : RS
        one_reg sreg(.clk, .rst_n, .wrt_tag_en(wrt_tag_en[i]), .wrt_tag(wrt_src), .w_data_src(cdb.data_src), .w_data(cdb.data),
                       .r_data(r_data_reg[i]), .d_sel(d_sel_reg[i]));
	end
	endgenerate

    assign r1_data = r_data_reg[re1_sel];
    assign r2_data = r_data_reg[re2_sel];
    assign r1_d_sel = d_sel_reg[re1_sel];
    assign r2_d_sel = d_sel_reg[re2_sel];
    //read on posedge
    // always @(posedge clk)
    //     if (r1)
    //         r1_data_t <= regfile[re1_sel];
    // always @(posedge clk)
    //     if (r2)
    //         r2_data_t <= regfile[re2_sel];

    //assign r1_data = r1_data_t;
    //assign r2_data = r2_data_t;
    //bypassing
    //assign r1_data = (real_w_en & (wrt_sel === re1_sel)) ? w_data : r1_data_t;
    //assign r2_data = (real_w_en & (wrt_sel === re2_sel)) ? w_data : r2_data_t;

endmodule

module RegFile(clk, rst_n, re1_sel, re2_sel, wrt_sel, w_data, w_en, r1_data, r2_data, r1, r2);
    parameter XLEN = 32;

    input  logic clk, rst_n, w_en;
    input  logic [4:0] re1_sel, re2_sel, wrt_sel;
    input  logic r1, r2;
    input  logic [XLEN-1:0] w_data;
    output logic [XLEN-1:0] r1_data, r2_data;


    logic [XLEN-1:0] regfile [31:0];
    logic [XLEN-1:0] r1_data_t, r2_data_t;
    logic real_w_en;

    assign real_w_en = w_en & |wrt_sel;

    initial
        regfile[0] = 0;

    //write on high
    always @(posedge clk)begin
        if (real_w_en) 
            regfile[wrt_sel] <= w_data;
    end
    //transparent read
    assign r1_data_t = regfile[re1_sel];
    assign r2_data_t = regfile[re2_sel];

    //read on posedge
    // always @(posedge clk)
    //     if (r1)
    //         r1_data_t <= regfile[re1_sel];
    // always @(posedge clk)
    //     if (r2)
    //         r2_data_t <= regfile[re2_sel];

    assign r1_data = r1_data_t;
    assign r2_data = r2_data_t;
    //bypassing
    //assign r1_data = (real_w_en & (wrt_sel === re1_sel)) ? w_data : r1_data_t;
    //assign r2_data = (real_w_en & (wrt_sel === re2_sel)) ? w_data : r2_data_t;

endmodule