module tb_alu();
    parameter XLEN = 32;
    logic signed [XLEN-1:0] a, b, out;
    logic [2:0] funct3;
    logic opt;

    ALU myALU(.in_a(a), .in_b(b), .funct3(funct3), .opt(opt), .out(out));

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, myALU);
        //ADD
        a = 128;
        b = -64;
        funct3 = 3'b000;
        opt = 0;
        #1
        if(out != a + b) $display("ADD failed. %d", out);
        //SUB
        a = 128;
        b = -64;
        funct3 = 3'b000;
        opt = 1;
        #1
        if(out != a - b) $display("SUB failed. %d", out);
        //SLT
        a = -64;
        b = 128;
        funct3 = 3'b010;
        opt = 0;
        #1
        if(out != {{XLEN-1{1'b0}}, a < b}) $display("SLT failed. %d", out);
        //SLTU
        a = -64;
        b = 128;
        funct3 = 3'b011;
        opt = 0;
        #1
        if(out != 0) $display("SLTU failed. %d", out);
        //XOR
        a = 128;
        b = -64;
        funct3 = 3'b100;
        opt = 0;
        #1
        if(out != (a ^ b)) $display("XOR failed. %d", out);
        //OR
        a = 128;
        b = -64;
        funct3 = 3'b110;
        opt = 0;
        #1
        if(out != (a | b)) $display("OR failed. %d", out);
        //AND
        a = 128;
        b = -64;
        funct3 = 3'b111;
        opt = 0;
        #1
        if(out != (a & b)) $display("AND failed. %d", out);
        //SLL
        a = 128;
        b = 33;
        funct3 = 3'b001;
        opt = 0;
        #1
        if(out != (a << (b&32'd31))) $display("SLL failed. %d", out);
        //SRL
        a = 128;
        b = 1;
        funct3 = 3'b101;
        opt = 0;
        #1
        if(out != (a >> b)) $display("SRL failed. %d", out);
        //SRA
        a = -128;
        b = 4;
        funct3 = 3'b101;
        opt = 1;
        #1
        if(out != (a >>> b)) $display("SRA failed. %d", out);
        $finish();
    end
endmodule