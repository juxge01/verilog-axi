iverilog -o pim.out ./testbench.v ./axi_ram.v ./axi_pim.v ./PIM_MODEL.v
vvp pim.out | tee -i result.log
gtkwave dump.vcd
