module debouncer(clk, rst_n, in, out);
    input logic clk, rst_n;
    input logic in;
    output logic out;

    logic [15:0] counter;

    always @(posedge clk, negedge rst_n)
    begin
        if(~rst_n)
            counter <= 0;
        else if(in != out)
            counter <= counter + 1;
        else
            counter <= 0;
    end
    
    always @(posedge clk, negedge rst_n)
        if(~rst_n)
            out <= 1'b0;
        else if(counter === '1)
            out <= in;
endmodule