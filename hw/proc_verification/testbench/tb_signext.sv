module tb_signext();
    logic signed [19:0] in;
    logic signed [31:0] out;
    Sign_Ext myext(.in(in), .out(out));
    initial begin
        for(in = -16; in <= 16; in = in + 1)
            #1 $monitor("orig: %d, ext: %d", in, out);
        $finish();
    end
endmodule