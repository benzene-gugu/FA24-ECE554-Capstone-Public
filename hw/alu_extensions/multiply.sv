
/*
    Multiplies 32-bit integers. Provides 32-bit integer result.
    funct3 determines operand signage and whether output is lower or higher bytes of the product.
    Assertion of start signal starts an operation. Assserts done signal when complete.
    Clears one signal on assertion of start.
    Assumes start signal is not asserted prior to successfully asserting previous operations' ack.
    However, asserting start and successfully asserting ack can be simultaneous.
    Value of result is not defined in between ack assertion and start assertion.
*/

// make mult_type_t type to make reading code & debugging easier
package mul_fn_pkg;
    typedef enum logic[1:0] {MUL, MULH, MULHSU, MULHU} mul_fn_t;
endpackage

module multiply
    #(
        parameter OP_LN = 32
    )
    (
    input wire clk, rst_n,
    input wire[OP_LN-1:0] op1, op2,
    input wire[2:0] funct3,
    input wire start, ack,
    output reg[OP_LN-1:0] result,
    output reg done
);

    import mul_fn_pkg::*;
    mul_fn_t mul_fn;
    assign mul_fn = mul_fn_t'(funct3[1:0]);



    // we make all operations into signed multiplication to unify logic
    logic signed [OP_LN:0] op1_real, op2_real;

    // lower bits are just the register contents
    assign op1_real[OP_LN-1:0] = op1;
    assign op2_real[OP_LN-1:0] = op2;

    logic op1_is_signed, op2_is_signed;
    assign op1_is_signed = ((mul_fn == MUL) || (mul_fn == MULH) || (mul_fn == MULHSU)); // or mul_fn != MULHU
    assign op2_is_signed = ((mul_fn == MUL) || (mul_fn == MULH));

    assign op1_real[OP_LN] = op1_is_signed ? op1[OP_LN-1] : 1'b0;
    assign op2_real[OP_LN] = op2_is_signed ? op2[OP_LN-1] : 1'b0;


    logic signed [2*OP_LN+1:0] product;
    assign product = op1_real * op2_real;


    wire [OP_LN-1:0] result_curr, result_nxt;
    // we have the full product, we choose what the result is based on the mult type
    assign result_curr = (mul_fn == MUL) ? product[OP_LN-1:0] :
                product[2*OP_LN-1:OP_LN];
    // result holds across clock only if done and waiting for ack
    assign result_nxt = (done && !ack) ? result : result_curr; 


    // multiplication is done in 1 cycle, so if prev. cycle is start asserted, next cycle is done asserted
    wire done_nxt;
    assign done_nxt = start || (done && !ack);

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            done <= 1'b0;
            result <= 0;
        end else begin    
            done <= done_nxt;
            result <= result_nxt;
        end
    end


endmodule