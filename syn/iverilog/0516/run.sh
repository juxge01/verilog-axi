iverilog -o pim.out ./tb_axi_pim.v ./PIM_MODEL.v ./axi_pim.v
vvp pim.out | tee -i result.log
# gtkwave dump.vcd
