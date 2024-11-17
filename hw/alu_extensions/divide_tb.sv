/*


*/

module divide_tb_multi();

    import divide_multi_doomed_params_pkg::*;

    reg clk, rst_n;
    reg[OP_LN-1:0] op1, op2;
    reg[2:0] funct3;
    reg start, ack;
    wire[OP_LN-1:0] result;
    wire done;

    // i test many random pairs at the end
    localparam NUM_RND_TESTS = 10 ** 1;

    localparam MAX_NEGATIVE = {1'b1, {OP_LN-1{1'b0}}};

    divide_multi #(.OP_LN(OP_LN), .NUM_ITER(NUM_ITER), .XP_LN(XP_LEN)) iDUT(.clk(clk), .rst_n(rst_n), .op1(op1), .op2(op2), .funct3(funct3), 
                    .start(start), .ack(ack), .result(result), .done(done));
    
    import div_t_pkg::*;
    div_fn_t div_fn;
    //assign div_fn = div_fn_t'(funct3[1:0]);
    assign funct3 = div_fn;

    logic [OP_LN-1:0] temp; // this is for storing values to check with later
    logic [OP_LN-1:0] expected;

    logic signed [OP_LN-1:0] op1_s, op2_s;
    assign op1_s = op1;
    assign op2_s = op2;

    integer num_right, num_wrong;

    initial begin

        $display("******** start of divide_tb ********\n");

        /*
            things to test:
            X reset
            check to see if done is clear at first after reset
            start, and see if done is asserted next cycle
            start & ack on same cycle
            test ack, should clear done
            delayed ack, should hold result
            different funct3 work correctly
            a few div operations to verify it is correct
        */

        /// initialize some variables (if I do it later, I get some issues)
        op1 = 0;
        op2 = 0;
        div_fn = div_fn_t'($random);
        start = 1'b0;
        ack = 1'b0;

        // I. reset module
        rst_n = 1'b1;
        repeat(2) @(negedge clk);
        rst_n = 1'b0;
        repeat(2) @(negedge clk);
        rst_n = 1'b1;
        repeat(2) @(negedge clk);

        assert(!done) else $error("done is asserted on initial reset");



        // II. checking that start, done, ack, work correctly with one another

        // a. start operation, check done is asserted after 1 cycle
        
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        repeat (NUM_CYCLES-1) @(negedge clk);
        assert(done) else $error("done is not asserted at expected time after start");

        ack = 1'b1;
        @(negedge clk);
        ack = 1'b0;
        assert(!done) else $error("done is not cleared after asserting ack");

        // b. start another operation 1 cycle after ack
        op1 = 1;
        op2 = 1;
        div_fn = DIVU;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        repeat (NUM_CYCLES-1) @(negedge clk);
        assert(done) else $error("done is not asserted at expected time after start");

        // c. start another operation immediately after ack
        op1 = 0;
        op2 = 1;
        ack = 1'b1;
        div_fn = REMU;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        ack = 1'b0;
        repeat (NUM_CYCLES-1) @(negedge clk);
        assert(done) else $error("done is not asserted at expected time after start");
        temp = result;

        // d. do not ack immediately, wait 2 cycles and see if done is still asserted with same value
        repeat (2) @(negedge clk);
        assert(done) else $error("done is not asserted at expected time after start");
        assert(result === temp) else $error("result changed before ack asserted");

        ack = 1'b1;
        @(negedge clk);
        ack = 1'b0;



        // III. testing that divide by 0, overflow, are working as intended

        // test div by 0, for all divide functions
        $display("\n--- testing divide by 0 case ---\n");
        for(int j = 0; j < 15; j = j + 1) // more iterations = more # of random tests = more confidence
            for(int i = 0; i < div_fn.num(); i = i + 1) // test with each of the divide function types
                test_this($random, 0, div_fn_t'(i));

        // test overflow
        $display("\n--- testing overflow case ---\n");
        test_this(MAX_NEGATIVE, {OP_LN{1'b1}}, DIV); // max_negative / -1
        test_this(MAX_NEGATIVE, {{OP_LN-1{1'b0}}, 1'b1}, DIV); // max_negative / 1
        test_this(MAX_NEGATIVE, {OP_LN{1'b1}}, REM); // max_negative / -1


        // IV. testing that cached results work as intended
        $display("\n--- testing cached results case ---\n");
        // simple cache case where numbers are positive
        test_this(5043, 261, REMU);
        div_fn = DIV;
        start = 1'b1;
        ack = 1'b1;
        @(negedge clk);
        assert(done) else $error("cached results not working");
        check_res();
        div_fn = REM;
        @(negedge clk);
        assert(done) else $error("cached results not working");
        check_res();
        div_fn = DIVU;
        @(negedge clk);
        assert(done) else $error("cached results not working");
        check_res();
        start = 1'b0;
        @(negedge clk);
        ack = 1'b0;

        // additional cache case: negative numbers.
        /* should not used cached result when treating as unsigned vs signed numbers, 
            as the magnitudes of the operands are different between the two cases */
        test_this(-1710598, -40, DIV);
        div_fn = REM;
        start = 1'b1;
        ack = 1'b1;
        @(negedge clk);
        assert(done) else $error("cached results not working");
        check_res();
        div_fn = REMU;
        @(negedge clk);
        assert(!done) else $error("seemed to use cache results in incorrect scenario");
        repeat (NUM_CYCLES-1) @(negedge clk);
        check_res();
        div_fn = DIVU;
        @(negedge clk);
        assert(done) else $error("cached results not working");
        check_res();
        start = 1'b0;
        @(negedge clk);
        ack = 1'b0;

        repeat(15) @(negedge clk);


        // random tests, can remove later

        

        repeat(20) @(negedge clk);



        // V. testing that the different modes of operation all work

        start = 1'b1;
        ack = 1'b1;

        num_right = 0;
        num_wrong = 0;

        
        $display("\n--- fully randomized testing ---\n");

        for (int i = 0; i < NUM_RND_TESTS; i = i + 1) begin
            test_rnd();
            //$display("%h/%h, %h/%h, %h", op1, op2, op1_s, op2_s, op1_s/op2_s);
        end

        $display("\n\nresults for fully randomized testing:\n");
        $display("# Correct: %d", num_right);
        $display("# Incorrect: %d", num_wrong);

        start = 1'b0;
        ack = 1'b0;

        repeat(20) @(negedge clk);

        $display("\nend of divide_tb!\n");
        $stop();

    end

    // clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // calculates expected results
    function logic [OP_LN-1:0] expected_result();
        logic [OP_LN-1:0] exp_norm, exp_div0, exp_ovfl, exp_full; // it seems like in more higher level like inital blocks, functions, there is implicit cast, not just bits being transfered
        // $display("%h/%h, %h/%h, %h, %h, %h", op1, op2, op1_s, op2_s, op1/op2, op1_s/op2_s, signed'(op1_s/op2_s));
        exp_norm = (op1 == MAX_NEGATIVE) && (op2 == {OP_LN{1'b1}}) ? 2 ** (OP_LN/2) : // overflow case creates FPE here, so we give alternate special value
                        (div_fn === DIV) ? signed'(op1_s/op2_s) : 
                        (div_fn === DIVU) ? (op1/op2) : 
                        (div_fn === REM) ? (op1_s - signed'(op1_s / op2_s) * op2_s) : 
                        (op1 - (op1 / op2) * op2);
        exp_div0 = ((div_fn === DIV) || (div_fn === DIVU)) ? ~0 : op1;
        exp_ovfl = (div_fn === DIV) ? MAX_NEGATIVE : 0;

        // we could add in the overflow case too

        exp_full = (op2 === 0) ? exp_div0 : 
                    (op1 == MAX_NEGATIVE) && (op2 == {OP_LN{1'b1}}) ? exp_ovfl :
                     exp_norm;

        return exp_full;
    endfunction

    task check_res();
        expected = expected_result(); //op1, op2, div_fn);
        assert(result === expected)
            begin
                num_right = num_right + 1;
                $display("correct, %s. %h/%h, expected %h, got %h", div_fn.name(), op1_s, op2_s, expected, result);
            end
            else begin
                num_wrong = num_wrong + 1;
                $display("incorrect, %s. %h/%h, expected %h, got %h", div_fn.name(), op1_s, op2_s, expected, result);
            end
    endtask

    task wait_n_check();
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        repeat (NUM_CYCLES-1) @(negedge clk);
        check_res();
        ack = 1'b1;
        @(negedge clk);
        ack = 1'b0;
    endtask

    task set_inputs(input logic [OP_LN-1:0] op1_set, op2_set, input div_fn_t div_fn_set);
        op1 = op1_set;
        op2 = op2_set;
        div_fn = div_fn_set;
    endtask

    task test_this(input logic [OP_LN-1:0] op1_set, op2_set, input div_fn_t div_fn_set);
        set_inputs(op1_set, op2_set, div_fn_set);
        wait_n_check();
    endtask

    // assumes start and ack are continuously asserted
    task test_rnd();
        op1 = $random;
        op2 = $dist_exponential($random, 2 ** 16);
        div_fn = div_fn_t'($random);
        // could use wait_n_check(), but this is special case where we assume start and ack continuous assert
        repeat (NUM_CYCLES) @(negedge clk);
        check_res();
    endtask


endmodule





// i got confused about signs and division in verilog specifically, made a test playground
module div_tb();
    logic [3:0] op1, op2;
    logic signed [3:0] op1_s, op2_s;

    assign op1_s = op1;
    assign op2_s = op2;

    logic [3:0] result;

    initial begin
        op1 = 4'b1001;
        #3;
        op2 = 4'b0010;
        #5;

        result = signed'(op1_s / op2_s);

        #3;

        $display("%b/%b, %b", op1_s, op2_s, result);
        $display("%d/%d, %d", op1_s, op2_s, result);

    end
endmodule


module divide_tb_single();

    import divide_multi_doomed_params_pkg::*;

    reg clk, rst_n;
    reg[OP_LN-1:0] op1, op2;
    reg[2:0] funct3;
    reg start, ack;
    wire[OP_LN-1:0] result;
    wire done;

    divide_single iDUT(.clk(clk), .rst_n(rst_n), .op1(op1), .op2(op2), .funct3(funct3), 
                    .start(start), .ack(ack), .result(result), .done(done));
    
    import div_t_pkg::*;
    div_fn_t div_fn;
    assign div_fn = div_fn_t'(funct3[1:0]);

    logic [OP_LN-1:0] temp; // this is for storing values to check with later
    logic [OP_LN-1:0] expected;

    logic signed [OP_LN-1:0] op1_s, op2_s;
    assign op1_s = op1;
    assign op2_s = op2;

    initial begin

        /*
            things to test:
            X reset
            check to see if done is clear at first after reset
            start, and see if done is asserted next cycle
            start & ack on same cycle
            test ack, should clear done
            delayed ack, should hold result
            different funct3 work correctly
            a few div operations to verify it is correct
        */

        /// initialize some variables (if I do it later, I get some issues)
        op1 = $random;
        op2 = $random;
        funct3 = 3'h0;
        start = 1'b0;
        ack = 1'b0;

        // I. reset module
        rst_n = 1'b1;
        repeat(2) @(negedge clk);
        rst_n = 1'b0;
        repeat(2) @(negedge clk);
        rst_n = 1'b1;
        repeat(2) @(negedge clk);

        assert(!done) else $display("done is asserted on initial reset");



        // II. checking that start, done, ack, work correctly with one another
        // (identical to a section in multiply_tb)

        // start operation, check done is asserted after 1 cycle
        
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        assert(done) else $display("done is not asserted 1 cycle after start");

        ack = 1'b1;
        @(negedge clk);
        ack = 1'b0;
        assert(!done) else $display("done is not cleared after asserting ack");

        // start another operation 1 cycle after ack
        op1 = $random;
        op2 = $random;
        funct3 = 3'h1;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        assert(done) else $display("done is not asserted 1 cycle after start");

        // start another operation immediately after ack
        ack = 1'b1;
        funct3 = 3'h2;
        start = 1'b1;
        @(negedge clk);
        ack = 1'b0;
        start = 1'b0;
        assert(done) else $display("done is not asserted 1 cycle after start");
        temp = result;

        // do not ack immediately, wait 2 cycles and see if done is still asserted with same value
        repeat(2) @(negedge clk);
        assert(done) else $display("done is not asserted 3 cycle after start");
        assert(result === temp) else $display("result changed before ack asserted");

        ack = 1'b1;
        @(negedge clk);
        ack = 1'b0;
        repeat(5) @(negedge clk);


        // III. testing that the different modes of operation all work

        for (int i = 0; i < 10; i = i + 1) begin
            op1 = $random;
            op2 = $random;
            
            // funct3 = 3'h3: REMU
            funct3 = 3'h3;
            start = 1'b1;
            @(negedge clk);
            ack = 1'b1;
            expected = op1 - (op1 / op2) * op2;
            assert(result === expected) else $display("incorrect result operating in REMU. expected %h, got %h", expected, result);

            // funct3 = 3'h2: REM
            funct3 = 3'h2;
            @(negedge clk);
            expected = op1_s - signed'(op1_s / op2_s) * op2_s;
            assert(result === expected) else $display("incorrect result operating in REM. expected %h, got %h", expected, result);

            // funct3 = 3'h1: DIVU
            funct3 = 3'h1;
            @(negedge clk);
            expected = op1 / op2;
            assert(result === expected) else $display("incorrect result operating in DIVU. expected %h, got %h", expected, result);

            // funct3 = 3'h0: DIV
            funct3 = 3'h0;
            @(negedge clk);
            start = 1'b0;
            expected = op1_s / op2_s;
            assert(result === expected) else $display("incorrect result operating in DIV. expected %h, got %h", expected, result);

        end

        ack = 1'b0;

        repeat(5) @(negedge clk);

        $display("end of divide_tb!");
        $stop();

    end

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


endmodule