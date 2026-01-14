filelist	="-f ./flist.f"
tb_file		="/home/admin/CapstoneProject3/01_tb/fec/rs_encoder_tb.sv"
time_unit	="-timescale 1ns/1ns"
acc_debug	="+access+rcw"
seed 		= +ntb_random_seed=automatic
wave_data	="waves.shm/"

.PHONY: clean
clean:
	@echo "-> CLEANING SIMULATION FILES"
	rm -rf INCA_libs *.shm *.history *.log *.ucdb *.fsdb xcelium.d xrun.* cov_work

PHONY:	sim
sim:	
	@echo "-> CLEANING SIMULATION FILES"
	rm -rf INCA_libs *.shm *.history *.log *.ucdb *.fsdb xcelium.d xrun.* cov_work
	@echo "-> SIMULATION"
	xrun $(GUI) +xm64bit -sv \
	$(filelist) \
	$(tb_file) \
	$(time_unit) \
	$(seed) \
	$(acc_debug)

.PHONY: gui
gui:
	@echo "-> SIMULATION WITH GUI"
	make sim GUI="-gui" &

PHONY: wave
wave:	
	@echo "-> WAVE"
	simvision $(wave_data) &

.PHONY: all
all: clean sim wave

distclean: clean
	@echo "-> DISTRIBUTION CLEAN REMOVING ALL FILES EXCEPT MAKEFILE, makefile, .f"
	find . -mindepth 1 ! -name "Makefile" ! -name "makefile" ! -name "*.f" -exec rm -rf {} +

.PHONY: kill
kill:
	@echo "-> KILLING SimVision"
	pkill -f simvision



