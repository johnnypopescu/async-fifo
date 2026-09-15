IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
BUILD    := build

RTL := rtl/sync_2ff.sv \
       rtl/fifo_mem.sv \
       rtl/wr_ptr_full.sv \
       rtl/rd_ptr_empty.sv \
       rtl/async_fifo.sv

.PHONY: sim sim-sync wave clean

# FIFO asincron: compilează și rulează testbench-ul, scrie build/wave.vcd
sim: | $(BUILD)
	$(IVERILOG) -g2012 -o $(BUILD)/tb_async_fifo.vvp $(RTL) tb/tb_async_fifo.sv
	$(VVP) $(BUILD)/tb_async_fifo.vvp

# FIFO sincron (încălzirea)
sim-sync: | $(BUILD)
	$(IVERILOG) -g2012 -o $(BUILD)/tb_sync_fifo.vvp rtl/sync_fifo.sv tb/tb_sync_fifo.sv
	$(VVP) $(BUILD)/tb_sync_fifo.vvp

wave:
	$(GTKWAVE) $(BUILD)/wave.vcd

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
