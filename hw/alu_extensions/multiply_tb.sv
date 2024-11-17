module multiply_tb();

    reg clk, rst_n;
    reg[31:0] op1, op2;
    reg[2:0] funct3;
    reg start, ack;
    wire[31:0] result;
    wire done;

    multiply #(.OP_LN(32)) iDUT(.clk(clk), .rst_n(rst_n), .op1(op1), .op2(op2), .funct3(funct3), 
                    .start(start), .ack(ack), .result(result), .done(done));
    
    import mul_fn_pkg::*;
    mul_fn_t mul_fn;
    assign mul_fn = mul_fn_t'(funct3[1:0]);

    logic [31:0] temp; // this is for storing values to check with later
    logic [63:0] product;


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
            a few mult operations to verify it is correct
        */

        $display("******** start of multiply_tb ********\n");

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
            
            // funct3 = 3'h3: MULHU
            funct3 = 3'h3;
            start = 1'b1;
            @(negedge clk);
            ack = 1'b1;
            product = op1 * op2;
            assert(result === product[63:32]) else $display("incorrect, MULHU. %h*%h, expected %h, got %h", op1, op2, product[63:32], result);

            // funct3 = 3'h2: MULHSU
            funct3 = 3'h2;
            @(negedge clk);
            product = signed'(op1) * signed'({1'b0,op2});
            assert(result === product[63:32]) else $display("incorrect, MULHSU. %h*%h, expected %h, got %h", op1, op2, product[63:32], result);

            // funct3 = 3'h1: MULH
            funct3 = 3'h1;
            @(negedge clk);
            product = signed'(op1) * signed'(op2); // why doesn't work?
            assert(result === product[63:32]) else $display("incorrect, MULH. %h*%h, expected %h, got %h", op1, op2, product[63:32], result);

            // funct3 = 3'h0: MUL
            funct3 = 3'h0;
            @(negedge clk);
            start = 1'b0;
            product = op1 * op2;
            assert(result === product[31:0]) else $display("incorrect, MUL. %h*%h, expected %h, got %h", op1, op2, product[31:0], result);

        end

        ack = 1'b0;

        repeat(5) @(negedge clk);

        $display("end of multiply_tb!");
        $stop();

    end

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


endmodule