FILES="rv32ui-p-addi.vh   rv32ui-p-bne.vh	rv32ui-p-sltu.vh
rv32ui-p-add.vh  	rv32ui-p-ori.vh      rv32ui-p-slt.vh
rv32ui-p-andi.vh   rv32ui-p-jalr.vh	rv32ui-p-or.vh	     rv32ui-p-srai.vh
rv32ui-p-and.vh    rv32ui-p-jal.vh	rv32ui-p-sb.vh	     rv32ui-p-sra.vh
rv32ui-p-auipc.vh  rv32ui-p-lbu.vh	rv32ui-p-sh.vh	     rv32ui-p-srli.vh
rv32ui-p-beq.vh    rv32ui-p-lb.vh	rv32ui-p-simple.vh   rv32ui-p-srl.vh
rv32ui-p-bgeu.vh   rv32ui-p-lhu.vh	rv32ui-p-slli.vh     rv32ui-p-sub.vh
rv32ui-p-bge.vh    rv32ui-p-lh.vh	rv32ui-p-sll.vh      rv32ui-p-sw.vh
rv32ui-p-bltu.vh   rv32ui-p-lui.vh	rv32ui-p-sltiu.vh    rv32ui-p-xori.vh
rv32ui-p-blt.vh    rv32ui-p-lw.vh	rv32ui-p-slti.vh     rv32ui-p-xor.vh"

for I in $FILES
do
	echo "testing file: $I"
	res=`vsim -c -do "vsim -voptargs=+acc work.tb_topcpu;mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b0.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b0; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b1.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b1; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b2.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b2; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b3.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b3; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b0.vh -format hex /tb_topcpu/iMEM/dmem/mem_b0; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b1.vh -format hex /tb_topcpu/iMEM/dmem/mem_b1; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b2.vh -format hex /tb_topcpu/iMEM/dmem/mem_b2; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b3.vh -format hex /tb_topcpu/iMEM/dmem/mem_b3; run -all;"`
	if [[ "$res" != *"PASS"* ]]; then
	vsim -c -do "vsim -voptargs=+acc work.tb_topcpu;mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b0.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b0; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b1.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b1; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b2.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b2; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b3.vh -format hex /tb_topcpu/iFetch/i_mem/mem_b3; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b0.vh -format hex /tb_topcpu/iMEM/dmem/mem_b0; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b1.vh -format hex /tb_topcpu/iMEM/dmem/mem_b1; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b2.vh -format hex /tb_topcpu/iMEM/dmem/mem_b2; mem load -i /filespace/y/yxia/projects/mRV32I/verification/verilog_4banks/${I}b3.vh -format hex /tb_topcpu/iMEM/dmem/mem_b3; log * -r; run -all;"
	fi
done

