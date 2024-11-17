module fifo_queue
    #(
        parameter WIDTH = 8,
        parameter SIZE = 8
    )
    (
        input clk,
        input rst_n,
        input read,
        input write,
        input [WIDTH-1:0] data_in,
        output empty,
        output full,
        output reg [WIDTH-1:0] data_out,
        output [$clog2(SIZE):0] num_entries // this is current number of entries (with data) in the queue
    );

    reg [WIDTH-1:0] storage[0:SIZE-1];
    reg [$clog2(SIZE)+1:0] new_ptr, old_ptr;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            new_ptr <= '0;
            old_ptr <= '0;
            data_out <= '0;
        end else begin
            if (write && !full) begin
                storage[new_ptr % SIZE] <= data_in;
                new_ptr <= new_ptr + 1;
            end

            if (read && !empty) begin
                old_ptr <= old_ptr + 1;
            end

            data_out <= storage[old_ptr % SIZE];
        end
    end

    assign num_entries = new_ptr - old_ptr;
    assign empty = (new_ptr == old_ptr);
    assign full = (num_entries == SIZE);

endmodule
