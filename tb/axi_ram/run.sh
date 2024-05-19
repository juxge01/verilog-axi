iverilog -o ram.out ./tb_axi_ram.v ../../rtl/axi_ram.v
vvp ram.out | tee -i result.log
gtkwave dump.vcd
