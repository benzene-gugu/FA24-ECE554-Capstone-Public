module tb_deb();
    logic in, out, clk, rst_n;

    debouncer iDUT(.clk, .rst_n, .in, .out);

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        repeat(10) @(negedge clk);
        rst_n = 1;

        in = 1;
        repeat(3) @(posedge clk);
        in = 0;
        repeat(10) @(posedge clk);
        in = 1;

        repeat(100000)@(posedge clk);

        in = 0;
        repeat(3) @(posedge clk);
        in = 1;
        repeat(10) @(posedge clk);
        in = 0;

        repeat(100000)@(posedge clk);
        $stop();
    end
    always
        #5 clk = ~clk;
endmodule