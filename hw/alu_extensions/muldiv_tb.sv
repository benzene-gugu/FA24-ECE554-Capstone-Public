module muldiv_tb ();
    
    reg clk, rst_n;
    reg[31:0] op1, op2;
    reg[2:0] funct3;
    reg start, ack;
    wire[31:0] result;
    wire done;

    muldiv #(.OP_LN(32)) iDUT(.clk(clk), .rst_n(rst_n), .op1(op1), .op2(op2), .funct3(funct3), 
                    .start(start), .ack(ack), .result(result), .done(done));

    initial begin

    end

    // clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

endmodule