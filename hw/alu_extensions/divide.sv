`default_nettype none

/*
    Divides 32-bit integers. Provides 32-bit integer result.
    - funct3 determines signed or unsigned operation, as well as whether to output 
    the quotient or the remainder
    - Assertion of start signal starts an operation. Assserts done signal when complete.
    - Clears done signal on assertion of start.
    - Assumes start signal is not asserted prior to asserting previous operations' ack.
    - However, asserting start and asserting ack can be simultaneous.
    - Value of result is not defined during cycles between ack assertion and start assertion.
*/

// create div_fn_t to make reading & debugging easier
package div_t_pkg;
    typedef enum logic[1:0] {DIV, DIVU, REM, REMU} div_fn_t;
    typedef enum logic[1:0] {NORMAL, DIV0, OVFL, CACHED} div_type_t;
endpackage


// 32 bit div, multi cycle
module divide_multi 
    #( // to use package, or to not use package?
        parameter OP_LN = 32,
        parameter NUM_ITER = 5, // number of iterations
        parameter XP_LN = 4 // extra precision length, must be >=1
    )
    (
    input wire clk, rst_n,
    input wire[OP_LN-1:0] op1, op2, // op1:dividend, op2:divisor
    input wire[2:0] funct3, // selects div_fn
    input wire start, ack, 
    output reg[OP_LN-1:0] result,
    output reg done
);
    import div_t_pkg::*;

    localparam OP_LN_LG = $clog2(OP_LN); // operation/operand length log
    localparam OP_LN_PLUS1_LG = $clog2(OP_LN+1);

    localparam C_LN = OP_LN + XP_LN; // calc length, bits used in calculation of calculating result, affects precision

    // how?: goldshmidt division algorithm
    // 5 iterations gives 32 bit precision
    // however, each iteration is pipelined to decrease combintaional delay and allow for faster clock
    
    /* 
        NOTE on terminology: 
        
        svd "saved" refers to last "NORMAL" (not divide by 0, overflow, or cached) 
        operation started before this cycle.

        For example, 2 cycles into operation X, the last operation started before
        this cycle is the current operation X.

        However, upon initiating an operation X, the last operation started before 
        this cycle is not the same as the current operation X that is just starting.
        
        curr "current" will often refer to the operation currently being attended to,
        which may not be related to the current operands at the input of the entire 
        divide module.
    */ 

    // we use unsigned (positive) magnitude of operands
    // we consider the signs at the end
    logic [OP_LN-1:0] op1_abs, op2_abs;
    
    logic ops_are_signed, ops_are_signed_svd;
    logic ops_have_signs, ops_have_signs_svd;


    logic op1_is_minus_curr, op2_is_minus_curr, op1_is_minus_svd, op2_is_minus_svd;
    logic [OP_LN-1:0] op1_abs_svd, op2_abs_svd;

    logic init, save_quo, save_rem, finish, skip;
    logic shft_iter; // shift in iterations, not the extra_shft
    //logic rem_vld, rem_vld_nxt;

    
    div_fn_t div_fn, div_fn_svd, div_fn_curr;
    assign div_fn = div_fn_t'(funct3[1:0]);

    assign div_fn_curr = init ? div_fn : div_fn_svd;


    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            div_fn_svd <= DIV;
        else if (!skip)
            div_fn_svd <= div_fn_curr;
    end

    logic div_remn_curr, div_remn_svd;
    assign div_remn_curr = (div_fn_curr == DIV || div_fn_curr == DIVU);
    assign div_remn_svd = (div_fn_svd == DIV || div_fn_svd == DIVU);

   

    div_type_t div_type, div_type_svd, div_type_curr;

    localparam MAX_NEGATIVE = {1'b1, {OP_LN-1{1'b0}}};

    assign div_type = (op2 == 0) ? DIV0 :
                        ((ops_are_signed) && (op1 == MAX_NEGATIVE) && (op2 == ~0)) ? OVFL : 
                        ((ops_have_signs == ops_have_signs_svd) && (op1_abs == op1_abs_svd) && (op2_abs == op2_abs_svd)) ? CACHED : 
                        NORMAL; // TODO: match the conditions for DIV0, etc.

    assign div_type_curr = init ? div_type : div_type_svd;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            div_type_svd <= NORMAL;
        else if (!skip)
            div_type_svd <= div_type_curr;
    end

    assign skip = (div_type_curr == DIV0) || (div_type_curr == OVFL) || (div_type_curr == CACHED);

    


    logic op1_is_minus, op2_is_minus;
    
    assign ops_are_signed = ((div_fn == DIV) || (div_fn == REM));
    assign ops_are_signed_svd = ((div_fn_svd == DIV) || (div_fn_svd == REM));

    assign ops_have_signs = op1_is_minus || op2_is_minus;
    assign ops_have_signs_svd = op1_is_minus_svd || op2_is_minus;

    assign op1_is_minus = ops_are_signed & op1[OP_LN-1];
    assign op2_is_minus = ops_are_signed & op2[OP_LN-1];

    assign op1_abs = op1_is_minus ? -(signed'(op1)) : op1;
    assign op2_abs = op2_is_minus ? -(signed'(op2)) : op2;

    /* 
        we track the is_minus and the abs because they will become
        useful at the end of the operation in determining results.
        The abs will also be useful in the start of the next operation.
    */

    assign op1_is_minus_curr = init ? op1_is_minus : op1_is_minus_svd;
    assign op2_is_minus_curr = init ? op2_is_minus : op2_is_minus_svd;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            op1_is_minus_svd <= 1'b0;
            op2_is_minus_svd <= 1'b0;
            // TODO: put in a default operation here
            op1_abs_svd <= 1;
            op2_abs_svd <= 1;
        end 
        else if (init && !skip) begin
            op1_is_minus_svd <= op1_is_minus_curr;
            op2_is_minus_svd <= op2_is_minus_curr;
            op1_abs_svd <= op1_abs;
            op2_abs_svd <= op2_abs;
        end
    end

    // TODO: may change this
    logic sign, sign_svd;

    assign sign = op1_is_minus ^ op2_is_minus;
    assign sign_svd = op1_is_minus_svd ^ op2_is_minus_svd;
    
    
    // counter up to 5/6 to track number of iterations through 

    logic [$clog2(OP_LN_LG):0] count_nxt, count, count_prv;
    logic count_inc;

    assign count_prv = init ? 0 : count; // intermediate signal for accounting for initialize
    assign count_nxt = count_inc ? count_prv + 1 : count_prv; // init becomes async
    // ^ now we must make sure count_inc does not depend on count

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            count <= 0;
        else
            count <= count_nxt;
    end

    logic count_done;
    assign count_done = (count == (NUM_ITER - 1)); // this gives 5 iterations




    // find first non-zero bit of op2
    logic [OP_LN_LG-1:0] op2_abs_first_high_bit;
    logic [OP_LN_LG:0] hbs1_res;
    highest_bit_set #(.WIDTH(OP_LN)) hbs1 (.bits(op2_abs), .res(hbs1_res));
    assign op2_abs_first_high_bit = hbs1_res[OP_LN_LG-1:0];

    logic half_case; // we want x to be [0, 0.5). that means 1-x in (0.5, 1]. there is special case at 0.5 in detecting hsb is not enough then

    logic [OP_LN_PLUS1_LG:0] extra_shft_nxt, extra_shft_init, extra_shft, extra_shft_early;
    assign extra_shft_init = {1'b0 , op2_abs_first_high_bit} + 1 + XP_LN - half_case; // hsb + 1 is to account for denominator 
    assign extra_shft_early = init ? extra_shft_init : extra_shft;
    assign extra_shft_nxt = shft_iter ? extra_shft_early - 1 : extra_shft_early;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            extra_shft <= 0;
        else
            extra_shft <= extra_shft_nxt;
    end


    // x_2n actually refers to x^(2^(n-1)) used in Goldschmidt division (binomial variation)
    logic [OP_LN-1:0] one_minus_x_first, one_minus_x, x;
    logic [C_LN-1:0] x_2n, x_2n_init, x_2n_prv, x_2n_nxt; // 3 more extra bits for more intermediate precision
    logic [2*C_LN-1:0] x_2n_sq;
    assign one_minus_x_first = op2_abs << (OP_LN - 1 - op2_abs_first_high_bit); // decimal point now is preceding msb: 0.1....
    assign half_case = (one_minus_x_first == {1'b1, {(OP_LN-1){1'b0}}}); // if 1-x = 0.5, we just shift back one bit so 1-x = 1
    assign one_minus_x = half_case ? 0 : one_minus_x_first; // in special case, we actually mean 1-x = 1, this effectively does that
    assign x = 0 - one_minus_x; // this is representing 1- (1-x), but the decimal place is preceding msb so the 1 can be neglected
    
    assign x_2n_init = {x, {XP_LN{1'b0}}};
    // assign x_2n_init[C_LN-1:C_LN-OP_LN] = x; // C_LN-OP_LN = XP_LN
    // assign x_2n_init[XP_LN-1:0] = 0;

    assign x_2n = init ? x_2n_init : x_2n_prv;
    assign x_2n_sq = x_2n * x_2n;
    assign x_2n_nxt = x_2n_sq[2*C_LN-1:C_LN];

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            x_2n_prv <= 0;
        else
            x_2n_prv <= x_2n_nxt;
    end



    logic [C_LN:0] mul_factor; // slightly larger than the typical calc length
    assign mul_factor = {1'b1, x_2n}; // 1 + x^(2^(n-1)), decimal point shifted by 35 bits left

    logic [C_LN-1:0] num, num_prv, num_early, num_init; // numerator (is 64 bit for more precision, but will only mult with lower 32)
    logic [2*C_LN:0] num_prod;
    //logic [6:0] num_hbs, num_shift_bits;
    assign num_init = {op1_abs, {XP_LN{1'b0}}}; //  decimal point shifted by 3 bit left
    assign num_early = init ? num_init : num_prv;
    assign num_prod = num_early * mul_factor; // RODO: CHANGE

    
    assign shft_iter = num_prod[2*C_LN];
    assign num = shft_iter ? num_prod[2*C_LN:C_LN+1] : num_prod[2*C_LN-1:C_LN];

    // may not need this
    // highest_bit_set #(.WIDTH(64)) hbs2 (.bits(num), .res(num_hbs));
    // assign num_shft_bits = num_hbs[6] ? 0 : // means no bits are high

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            num_prv <= 0;
        else
            num_prv <= num;
    end

    logic [OP_LN-1:0] quo, rem;
    logic [OP_LN-1:0] quo_abs, rem_abs, quo_abs_svd, rem_abs_svd;
    
    logic [C_LN-1:0] num_rnd_add;
    logic [C_LN:0] num_rnd, num_eff; // adding two numbers, account for one more digit overflow
    // assign num_rnd_add = { {(OP_LN-1){1'b0}}, {(XP_LN-2){1'b0}}, {2{1'b1}} }; // just pushes the value over
    // assign num_rnd_add = { {(OP_LN-1){1'b0}}, {(XP_LN-1){1'b0}}, 1'b1 }; // just pushes the value over
    assign num_rnd_add = { {(OP_LN-1){1'b0}}, 1'b0, {(XP_LN-1){1'b1}} }; // rounds down
    // assign num_rnd_add = { {(OP_LN-1){1'b0}}, num_prv[XP_LN], {(XP_LN-1){~num_prv[XP_LN]}} }; // rounds towards nearest even number
    assign num_rnd = num_prv + num_rnd_add;
    assign num_eff = num_rnd >> extra_shft;
    assign quo_abs = num_eff[OP_LN-1:0];
    assign quo = sign_svd ? -(signed'(quo_abs)) : quo_abs;
    assign rem_abs = op1_abs_svd - op2_abs_svd * quo_abs;
    assign rem = op1_is_minus_svd ? -(signed'(rem_abs)) : rem_abs;

    

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            quo_abs_svd <= 1;
        else if (save_quo)
            quo_abs_svd <= quo_abs;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            rem_abs_svd <= 0;
        else if (save_rem)
            rem_abs_svd <= rem_abs;
    end

    


    logic [OP_LN-1:0] result_nxt, result_full;
    logic [OP_LN-1:0] quo_full, rem_full;
    logic [OP_LN-1:0] quo_cached, rem_cached, rem_skip_cached;
    assign quo_cached = sign ? -(signed'(quo_abs_svd)) : quo_abs_svd;
    //assign rem_skip_cached = op1_is_minus ? -rem_abs : rem_abs;
    assign rem_cached = // save_rem ? rem_skip_cached :
                        op1_is_minus ? -(signed'(rem_abs_svd)) : rem_abs_svd;
    
    // div by 0: result = -1 for div, op1 for rem
    // overflow (only signed -MAX/-1 op): -max for div, 0 for rem

    assign quo_full = (div_type_curr == NORMAL) ? quo : 
                        (div_type_curr == DIV0) ? signed'(-1) :
                        (div_type_curr == OVFL) ? op1 :
                        // (div_type_curr == CACHED) ?
                        quo_cached;

    assign rem_full = (div_type_curr == NORMAL) ? rem : 
                        (div_type_curr == DIV0) ? op1 :
                        (div_type_curr == OVFL) ? 0 :
                        // (div_type_curr == CACHED) ?
                        rem_cached;

    assign result_full = div_remn_curr ? quo_full : rem_full;

    assign result_nxt = finish ? result_full : result; 
    // assumption: start will only be asserted at same time or after ack

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            result <= 1;
        else
            result <= result_nxt;
    end
    // ff res_ff(.clk(clk), .rst_n(rst_n), .q_rst(1), .q_nxt(result_nxt), .q(result));

    logic done_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            done <= 1'b0;
        else
            done <= done_nxt;
    end
    // ff done_ff(.clk(clk), .rst_n(rst_n), .q_rst(1'b0), .q_nxt(done_nxt), .q(done));

    // always_ff @(posedge clk, negedge rst_n) begin
    //     if(!rst_n)
    //         rem_vld <= 1'b0;
    //     else
    //         rem_vld <= rem_vld_nxt;
    // end

    


    typedef enum logic [1:0] {IDLE, ITERATE, CALC_REM} state_t;

    state_t state, state_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            state <= IDLE;
        else
            state <= state_nxt;
    end
    
    always_comb begin
        state_nxt = state;
        init = 1'b0;
        count_inc = 1'b0;
        done_nxt = 1'b0;
        save_quo = 1'b0;
        save_rem = 1'b0;
        // rem_vld_nxt = rem_vld;
        finish = 1'b0;
        case (state)
            IDLE: begin
                if(done && !ack)
                    done_nxt = 1'b1;
                else begin
                    if(start) begin
                        init = 1'b1;
                        if(skip) begin // skip but not cached
                            // implied: state_nxt = IDLE;
                            done_nxt = 1'b1;
                            finish = 1'b1;
                            // if((div_type_curr == CACHED) && !div_remn_curr && !rem_vld) begin
                            //     save_rem = 1'b1;
                            //     rem_vld_nxt = 1'b1;
                            // end
                            
                        end else begin
                            state_nxt = ITERATE;
                            count_inc = 1'b1;
                        end
                    end
                end
            end
            ITERATE: begin
                count_inc = 1'b1;
                if(count_done) begin
                    
                    // if(div_remn_curr) begin
                    //     state_nxt = IDLE;
                    //     // rem_vld_nxt = 1'b0;
                    //     finish = 1'b1;
                    //     done_nxt = 1'b1;
                    // end else begin
                        state_nxt = CALC_REM;
                    // end
                end
            end
            CALC_REM: begin
                save_quo = 1'b1;
                save_rem = 1'b1;
                // rem_vld_nxt = 1'b1;
                state_nxt = IDLE;
                finish = 1'b1;
                done_nxt = 1'b1;
            end
        endcase
    end
    

endmodule


// helper module
module highest_bit_set
    #(parameter WIDTH=32)
    (
    input wire [WIDTH-1:0] bits,
    output reg [$clog2(WIDTH):0] res
);
    // source https://stackoverflow.com/questions/38230450/first-non-zero-element-encoder-in-verilog
    // actually, we may not need this [no, we do!]
    wire [$clog2(WIDTH):0] out_stage[0:WIDTH];
    assign out_stage[0] = ~0;
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: hbs_gen
            assign out_stage[i+1] = bits[i] ? i : out_stage[i]; 
        end
    endgenerate
    assign res = out_stage[WIDTH];

endmodule


// thought maybe this can simplify code, but haven't used it yet
module ff(
    input wire clk,
    input wire rst_n,
    input wire q_rst,
    input wire q_nxt,
    output reg q
);

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            q <= q_rst;
        else
            q <= q_nxt;
    end

endmodule



// div, single cycle for now, maybe will change to multi cycle
module divide_single(
    input wire clk, rst_n,
    input wire[31:0] op1, op2, // op1:dividend, op2:divisor
    input wire[2:0] funct3, // selects div_fn
    input wire start, ack, 
    output reg[31:0] result,
    output reg done
);

    // TODO: NOTE DIVIDE BY 0 and OVFL

    import div_t_pkg::*;
    div_fn_t div_fn;
    assign div_fn = div_fn_t'(funct3[1:0]);


    // we transform all operations to signed 33 bit division to unify logic

    logic signed [32:0] op1_real, op2_real;

    assign op1_real[31:0] = op1;
    assign op2_real[31:0] = op2;
    
    logic ops_are_signed;
    assign ops_are_signed = ((div_fn == DIV) || (div_fn == REM));

    assign op1_real[32] = ops_are_signed & op1[31];
    assign op2_real[32] = ops_are_signed & op2[31];

    logic signed [32:0] quotient, remainder;
    
    assign quotient = op1_real / op2_real;
    assign remainder = op1_real - op2_real * quotient;

    logic signed [32:0] remainder_abs;
    
    // take abs value of remainder
    //assign remainder_abs = remainder[32] ? -remainder : remainder;

    wire [31:0] result_curr, result_nxt;
    // we have full product, we choose what result is based on funct3
    assign result_curr = (div_fn == DIV || div_fn == DIVU) ? quotient[31:0] :
                remainder[31:0];
    // result stays same across clock if done & waiting for ack
    assign result_nxt = (done && !ack) ? result : result_curr; 
    // assumption: start will only be asserted at same time or after ack


    // we pretend div is 1 cycle (it is for now!)
    wire done_nxt;
    assign done_nxt = start || (done && !ack);

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            done <= 1'b0;
            result <= 32'h0;
        end else begin    
            done <= done_nxt;
            result <= result_nxt;
        end
    end

endmodule

`default_nettype wire