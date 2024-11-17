
package divide_multi_doomed_params_pkg;
    localparam OP_LN = 32;
    localparam NUM_ITER = 6; // is also cycles per fresh operation. as 1 iteration takes 1 cycle
    localparam XP_LEN = 4; // must be >=1
    localparam NUM_CYCLES = NUM_ITER + 1; // # cycles for 1 divide operation, the + _ depends on the version of divide_multi
endpackage