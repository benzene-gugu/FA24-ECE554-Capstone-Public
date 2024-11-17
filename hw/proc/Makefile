#https://veripool.org/guide/latest/verilating.html
SRCFILES= $(wildcard *.sv)
TSTFILES= $(wildcard verification/tests/*.sv)

check: $(SRCFILES) $(TSTFILES)
	verilator -Wno-MULTITOP -Wno-STMTDLY --timing --lint-only $(SRCFILES) $(TSTFILES)

tb_alu: $(SRCF_ILES) $(TSTFILES)
	verilator --top-module tb_alu --binary --trace $(SRCFILES) $(TSTFILES)
	cd obj_dir && ./Vtb_alu

tb_reg: $(SRCF_ILES) $(TSTFILES)
	verilator --top-module tb_reg --binary --trace $(SRCFILES) $(TSTFILES)
	cd obj_dir && ./Vtb_reg

tb_reg_ooo: $(SRCF_ILES) $(TSTFILES)
	verilator --top-module tb_reg_ooo --binary --trace $(SRCFILES) $(TSTFILES)
	cd obj_dir && ./Vtb_reg_ooo

tb_signext: $(SRCF_ILES) $(TSTFILES)
	verilator --top-module tb_signext --binary --trace $(SRCFILES) $(TSTFILES)
	cd obj_dir && ./Vtb_signext

tb_resv: $(SRCF_ILES) $(TSTFILES)
	verilator --top-module tb_resv --binary --trace $(SRCFILES) $(TSTFILES)
	cd obj_dir && ./Vtb_resv

clean:
	rm -rf obj_dir
