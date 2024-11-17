/*
SPART Transmitter sub module.
By Yu Xia
*/
module peripheral_spart_tx( //ports directly connect to upper level design
    input logic clk,
    input logic rst_n,
    input logic [12:0] DB,
    input logic       ioaddr,
    input logic [7:0] databus,
    input logic iocs_n,
    input logic iorw_n,
    output logic TX,
    output logic tx_q_empty,
    output logic tx_q_full,
    output logic [3:0] ptr_rd_tx,
    output logic [3:0] ptr_wr_tx// The pointers for the circular queues
);
    logic [12:0] dwn_ctr_tx; // The Baud rate down counters and the Baud rate divisor buffer
    logic [7:0] txbuffer[8:0];

    /*================================================================================tx part*/
    //baudrate gen
    logic [7:0] txbuf; // The buffer for the TX data
    logic enable_tx, begin_tx; // Contral signals for the transmission of TX data
    // The down counter for the baud rate generation for TX
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            dwn_ctr_tx <= 0;
        else if((dwn_ctr_tx === 0) | begin_tx) //rest on 0 or begin
            dwn_ctr_tx <= DB;
        else 
            dwn_ctr_tx <= dwn_ctr_tx - 1;
    end
    assign enable_tx = dwn_ctr_tx === 0; // Enable a TX transmission when the down counter reaches 0

    logic tx_incr_bit; // The signal to increment the bit counter for the TX transmission
    
    //maintaining the queue and buffer
    wire [3:0] tx_tmp_wr_p_1; // Temporary write pointer for TX buffer that is kept within the range of 0-8
    assign tx_tmp_wr_p_1 = ptr_wr_tx === 4'd8 ? 0 : ptr_wr_tx + 1; //saved, only allows 0-8
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)begin
            ptr_rd_tx <= 0;
            ptr_wr_tx <= 0;
            txbuf <= 0;
        end
        else begin
            if((ioaddr === 1'b0) & ~iocs_n & ~iorw_n & ~tx_q_full) begin//allow write tx on non-full
                txbuffer[ptr_wr_tx] <= databus; //read in data
                ptr_wr_tx <= tx_tmp_wr_p_1; //0-8 are possible
            end
            if(begin_tx) begin //read buffer to transmit on start
                ptr_rd_tx <= ptr_rd_tx === 4'd8 ? 0 : ptr_rd_tx + 1; //discard read val after read, 0-8 are possible
                txbuf <= txbuffer[ptr_rd_tx]; //read buf
            end
            else if(tx_incr_bit)
                txbuf <= txbuf >> 1;
        end
    end
    assign tx_q_full = tx_tmp_wr_p_1 === ptr_rd_tx; //test full, leave cur pos empty
    assign tx_q_empty = ptr_rd_tx === ptr_wr_tx; //test empty

    enum logic [1:0] {IDLE, START, SEND, STOP} tx_state, tx_nxt_state;

    logic [2:0] tx_bit_ctr; //bit counter
    //manage bit ctr and state reg
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            tx_state <= IDLE;
            tx_bit_ctr <= 0;
        end
        else begin
            tx_state <= tx_nxt_state;
            if(begin_tx) //at start, clear bit ctr
                tx_bit_ctr <= 0;
            else tx_bit_ctr <= tx_bit_ctr + tx_incr_bit;
        end

    always_comb begin
        tx_incr_bit = 0;
        begin_tx = 0;
        TX = 1; //idle, stop default
        tx_nxt_state = tx_state;
        case (tx_state)
            IDLE: begin
                if(!tx_q_empty) begin
                    tx_nxt_state = START;
                    begin_tx = 1; //signal start
                end
            end 
            START: begin
                TX = 0;//start
                if(enable_tx)
                    tx_nxt_state = SEND;
            end
            SEND: begin
                TX = txbuf[0]; //send data
                if(enable_tx & (tx_bit_ctr !== 3'd7)) //not last bit
                    tx_incr_bit = 1; //bit count ++, shift out the bit done
                else if(enable_tx & (tx_bit_ctr === 3'd7)) //last bit
                    tx_nxt_state = STOP;
            end 
            STOP: begin
                if(enable_tx & !tx_q_empty) begin //not empty, direct to start
                    tx_nxt_state = START;
                    begin_tx = 1;
                end
                else if(enable_tx) //empty, go idle
                    tx_nxt_state = IDLE;
            end 
        endcase
    end
    /*end tx part============================================================================*/
endmodule