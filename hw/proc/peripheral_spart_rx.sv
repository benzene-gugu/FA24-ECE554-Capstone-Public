/*
SPART Reciver sub module.
By Yu Xia
*/
module peripheral_spart_rx(//ports directly connect to upper level design
    input logic clk,
    input logic rst_n,
    input logic [12:0] DB,
    input logic        ioaddr,
    input logic iocs_n,
    input logic iorw_n,
    input logic RX_raw,
    output logic [7:0] rxdataout,
    output logic rx_q_empty,
    output logic rx_q_full,
    output logic [3:0] ptr_rd_rx,
    output logic [3:0] ptr_wr_rx// The pointers for the circular queues
);
    logic [12:0] dwn_ctr_rx; // The Baud rate down counters and the Baud rate divisor buffer
    logic [7:0] rxbuffer[8:0];
    logic RX, RX_int;
    assign rxdataout = rxbuffer[ptr_rd_rx];

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n) begin
            RX_int <= 1'b1;
            RX <= 1'b1;
        end
        else begin
            RX_int <= RX_raw;
            RX <= RX_int;
        end

    /*================================================================================rx part*/
    //baudrate gen
    logic [7:0] rxbuf;
    logic enable_rx, begin_rx, done_rx;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            dwn_ctr_rx <= 0;
        else if((dwn_ctr_rx === 0) | begin_rx) //rest on 0 or begin
            dwn_ctr_rx <= DB;
        else 
            dwn_ctr_rx <= dwn_ctr_rx - 1;
    end
    assign enable_rx = dwn_ctr_rx === (DB>>1);

    logic rx_incr_bit;
    
    //maintaining the queue and buffer
    wire [3:0] rx_tmp_wr_p_1;
    assign rx_tmp_wr_p_1 = ptr_wr_rx === 4'd8 ? 0 : ptr_wr_rx + 1; //saved, only allows 0-8
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)begin
            ptr_rd_rx <= 0;
            ptr_wr_rx <= 0;
            rxbuf <= 0;
        end
        else begin
            if(done_rx & ~rx_q_full) begin//a finished read, only write on non-full
                rxbuffer[ptr_wr_rx] <= rxbuf; //write buf
                ptr_wr_rx <= rx_tmp_wr_p_1; //0-8 are possible
            end
            if((ioaddr === 1'b0) & ~iocs_n & iorw_n & ~rx_q_empty) begin //allow read only on non-empty
                ptr_rd_rx <= ptr_rd_rx === 4'd8 ? 0 : ptr_rd_rx + 1; //discard read val, 0-8 are possible
            end
            else if(rx_incr_bit) //read and shift, discard lsb
                rxbuf <= {RX, rxbuf[7:1]};
        end
    end
    assign rx_q_full = rx_tmp_wr_p_1 === ptr_rd_rx; //test full, leave cur pos empty
    assign rx_q_empty = ptr_rd_rx === ptr_wr_rx; //test empty

    enum logic [1:0] {IDLE_rx, START_rx, RECV, STOP_rx} rx_state, rx_nxt_state;

    logic [2:0] rx_bit_ctr; //bit counter
    //manage bit ctr and state reg
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            rx_state <= IDLE_rx;
            rx_bit_ctr <= 0;
        end
        else begin
            rx_state <= rx_nxt_state;
            if(begin_rx) //at start, clear bit ctr
                rx_bit_ctr <= 0;
            else rx_bit_ctr <= rx_bit_ctr + rx_incr_bit;
        end

    always_comb begin
        rx_incr_bit = 0;
        begin_rx = 0;
        done_rx = 0;
        rx_nxt_state = rx_state;
        case (rx_state)
            IDLE_rx: begin
                if(~RX) begin
                    rx_nxt_state = START_rx;
                    begin_rx = 1; //signal start
                end
            end 
            START_rx: begin
                if(enable_rx)
                    rx_nxt_state = RECV;
            end
            RECV: begin
                if(enable_rx) begin
                    rx_incr_bit = 1; //bit count ++, lsb out
                    if(rx_bit_ctr === 3'd7) //last bit
                        rx_nxt_state = STOP_rx;
                end
            end 
            STOP_rx: begin
                if(enable_rx)begin //done this packet, save and go idle
                    done_rx = 1;
                    rx_nxt_state = IDLE_rx;
                end
            end 
        endcase
    end
    /*end rx part============================================================================*/
endmodule