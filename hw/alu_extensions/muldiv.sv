module muldiv
   #( // to use package, or to not use package?
        parameter OP_LN = 32
    )
    (
    input wire clk, rst_n,
    input wire[OP_LN-1:0] op1, op2, // op1:dividend, op2:divisor
    input wire[2:0] funct3, // selects div_fn
    input wire start, ack, 
    output reg[OP_LN-1:0] result,
    output reg done
);

    wire start_mul, start_div;

    assign start_mul = start && !funct3[2];
    assign start_div = start && funct3[2];

    multiply #(.OP_LN(OP_LN)) iMul(.clk(clk), .rst_n(rst_n), .op1(op1), .op2(op2), .funct3(funct3), 
                    .start(start_mul), .ack(ack), .result(result), .done(done));

    import divide_multi_doomed_params_pkg::*;

    divide_multi #(.OP_LN(OP_LN), .NUM_ITER(NUM_ITER), .XP_LN(XP_LEN)) iDiv(.clk(clk), .rst_n(rst_n), .op1(op1), .op2(op2), .funct3(funct3), 
                    .start(start_div), .ack(ack), .result(result), .done(done));

endmodule