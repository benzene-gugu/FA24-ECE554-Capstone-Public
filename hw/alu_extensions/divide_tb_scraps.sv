
//code that i am scrapping away

//i just cut and paste to here



//helpful macros

`define test_pair(OP1, OP2, DIV_FN) \
    op1 = OP1; \
    op2 = OP2; \
    div_fn = DIV_FN; \
    start = 1'b1; \
    @(negedge clk); \
    start = 1'b0; \
    repeat (NUM_CYCLES-1) @(negedge clk); \
    ack = 1'b1; \
    @(negedge clk); \
    ack = 1'b0;

`define check_res \
    expected = expected_result(); //op1, op2, div_fn); \
    assert(result === expected) \
        begin \
            num_right = num_right + 1; \
            $display("correct, %s. %h/%h, expected %h, got %h", div_fn.name(), op1_s, op2_s, expected, result); \
        end \
        else begin \
            num_wrong = num_wrong + 1; \
            $display("incorrect, %s. %h/%h, expected %h, got %h", div_fn.name(), op1_s, op2_s, expected, result); \
        end

`define test(OP1, OP2, DIV_FN) \
    op1 = OP1; \
    op2 = OP2; \
    div_fn = DIV_FN;\
    repeat (NUM_CYCLES) @(negedge clk); \
    `check_res
    

`define test_rnd \
    op1 = $random; \
    op2 = $dist_exponential($random, 2 ** 16); \
    div_fn = div_fn_t'($random); \
    repeat (NUM_CYCLES) @(negedge clk); \
    `check_res


// random tests

// op1 = 32'h9e32a63c;
        // op2 = 32'h000560dc;
        // funct3 = 3'h1;
        // start = 1'b1;
        // @(negedge clk);
        // start = 1'b0;
        // repeat (4) @(negedge clk);
        // ack = 1'b1;
        // @(negedge clk);
        // ack = 1'b0;

        test_this(32'h9e32a63c, 32'h000560dc, DIV);
        test_this(32'h9e32f634, 32'h00000001, DIV);

        test_this(32'hc27c9684, 32'h00000ad7, DIV); // s
        test_this(32'hc27c9684, 32'h00000ad7, DIVU); // u

        test_this(32'h48dba791, 32'h0000233f, REM); // su

// testing loops
        // for (int i = 0; i < NUM_TEST_PAIRS; i = i + 1) begin
        //     op1 = $random;
        //     op2 = $dist_exponential($random, 2 ** 16);
        //     // op2 = $random;
        //     // op2 = $exp(op2[5:0]) / $exp(2 ** 32);

            
        //     `test_rnd(op1, op2, REM, op1_s - signed'(op1_s / op2_s) * op2_s)
        //     `test_rnd(op1, op2, REMU, op1 - (op1 / op2) * op2)
        //     `test_rnd(op1, op2, DIV, op1/op2)
        //     `test_rnd(op1, op2, DIVU, op1_s/op2_s)

        // end