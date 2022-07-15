#******************************************************************************
#    Expanding upon the repo by Noureddine Ait Said : 
#		https://github.com/noureddine-as/riscv-baremetal-DefaultConfig
#------------------------------------------------------------------------------

.SECONDARY: # Used to stop make from deleting intermediate files

# Default targets are just the final ones (not including intermediate targets)
default: assembly
default: disassembly
default: histogram
default: extract_main
default: bandwidth

# Checking if a RISCV compiler is present
ifndef RISCV
$(error "[ ERROR ] - RISCV variable not set!")
endif

# ------------------------ Variable definitions -------------------------

# 	Macro definitions for directories to be used in the compile lines
# /src - Contains input .c files
SRC_DIR 		= ./src
# /src/common - Contains shared files between inputs e.g. syscalls.c
SRC_COMMON_DIR  = ./src/common
# /build - Constructed directory used to store outputs from recipes including
#	executables, instruction traces, display pngs etc.
BUILD_DIR 		= ./build

# Include flag used in compile lines to include header files needed when
#	compiling using the embecosm compilers
INCLUDES 		= -I./include

LINKER_SCRIPT 	= link.ld

# Makefile functions and variables used to parse the input .csv file here
MK_CSV 			:= ./csv/csv.mk
# Input CSV file
CSV 			?= ./csv/config5.csv

$(shell echo CSV FNAME currently set to : ${CSV})

include ${MK_CSV}

# In this Makefile, there are two sets of variables detailing the information
#	from the CSV files:
#	- Variables read from the CSV - We initially directly read the information 
#	from the CSVs and store them in variables/lists prefixed with 'R_'. This
#	allows us to set up the recipe targets and have the CSV information present
#	in the file path which can be read from after.
#	- Variables read using the pattern rule - We can only access specific values
#	in the recipe of a target but taking the information from the file path which
#	we can access using the pattern rule. These variables parse the file path for
#	each specific target and use that information in the recipes as desired

# ----- Variables based on the CSV - Used for initial directory formatting -----
# 	Forms lists of the values in specific columns
# ISA instruction word size - 32 or 64
R_XLEN		= $(call CSV_COL,1,${row})
# Compiler - gcc or clang
R_COMPILER	= $(call CSV_COL,2,${row})
# ISA - String detailing the ISA following the RISC-V naming convention
R_ISA		= $(call CSV_COL,3,${row})
# ABI - Application binary interface : ilp32, lp64 or ilp32e
R_ABI		= $(call CSV_COL,4,${row})
# NPROC - How many cores we are using to simulate the program
R_NPROC 	= $(call CSV_COL,5,${row})
# FNAME - Input ML program name
R_FNAME		= $(call CSV_COL,6,${row})

# ---------------------------- Forming the targets ----------------------------
# Targets are created under directory paths formed by the information from the CSV files
#	collected in the variables prefixed with 'R_'

# TRACES is a list holding all instruction trace target directory paths which 
# 	will be used to form the other targets. Formed by looking at all rows of the CSV 
# 	e.g. build/rv32gc-ilp32-gcc/cv_testcase/nproc-8/testcase.trc
#		 build/$(isa)-$(abi)-$(compiler)/$(fname)/testcase.trc
TRACES := $(foreach row,${CSV_ROWS},$\
	${BUILD_DIR}/$\
	rv$(call R_XLEN)$(call R_ISA)-$(call R_ABI)-$(call R_COMPILER)/$\
	$(call R_FNAME)/nproc-$(call R_NPROC)/testcase.trc)

# 	Form the other targets using string manipulation with the current target
# main.trc - Section of instruction trace between where we enter and leave main
MAIN_TRACES 	   := $(subst testcase,main,${TRACES})

# 	Directory names - Formed by adjusting the TRACES list
# nproc - subdirectories used to contain the files associated with
#	simulating with a specific number of processors
NPROC_DIRS 	:= $(dir ${TRACES})
# fname - subdirectories holding all files related to a single input ML file
FNAME_DIRS 	:= $(addsuffix ../,${NPROC_DIRS})
# common - subdirectory used to store temporary files used by multiple test cases
COMMON_DIRS := $(addsuffix ../common,${FNAME_DIRS})
# figures - subdirectories for any figures
FIGURE_DIRS := $(addsuffix figures/,${NPROC_DIRS})
LOAD_BW_FIG_DIRS  := $(addsuffix bw/load/,${FIGURE_DIRS})
STORE_BW_FIG_DIRS := $(addsuffix bw/store/,${FIGURE_DIRS})

#	Target files
OBJECTS 		   := $(addsuffix testcase.o,${FNAME_DIRS})
# Histograms produced by Spike
HISTOGRAMS 		   := $(subst .o,.hst,${OBJECTS})
EXECUTABLES 	   := $(subst .o,.elf,${OBJECTS})
ASSEMBLIES 	   	   := $(subst .o,.S,${OBJECTS})
DISASSEMBLIES 	   := $(subst .o,.dasm,${OBJECTS})
# (main) section of the disassembly
MAIN_DISASSEMBLIES := $(subst testcase.dasm,main.dasm,${DISASSEMBLIES})

#	Figures
LOAD_BYTE_FIGURE  := $(addsuffix load_byte.txt,${FIGURE_DIRS})
LOAD_BYTE_ALL  	  := $(addsuffix load_byte_*.pdf,${FIGURE_DIRS})
STORE_BYTE_FIGURE := $(addsuffix store_byte.txt,${FIGURE_DIRS})

LOAD_BW_2		  := $(addsuffix load_bw_2.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_2_TRC	  := $(addsuffix load_bw_2.trc,${LOAD_BW_FIG_DIRS})

LOAD_BW_4		  := $(addsuffix load_bw_4.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_4_TRC	  := $(addsuffix load_bw_4.trc,${LOAD_BW_FIG_DIRS})

LOAD_BW_8		  := $(addsuffix load_bw_8.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_8_TRC	  := $(addsuffix load_bw_8.trc,${LOAD_BW_FIG_DIRS})

LOAD_BW_16	  	  := $(addsuffix load_bw_16.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_16_TRC	  := $(addsuffix load_bw_16.trc,${LOAD_BW_FIG_DIRS})

LOAD_BW_32	  	  := $(addsuffix load_bw_32.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_32_TRC	  := $(addsuffix load_bw_32.trc,${LOAD_BW_FIG_DIRS})

LOAD_BW_64	  	  := $(addsuffix load_bw_64.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_64_TRC	  := $(addsuffix load_bw_64.trc,${LOAD_BW_FIG_DIRS})

LOAD_BW_128	  	  := $(addsuffix load_bw_128.pdf,${LOAD_BW_FIG_DIRS})
LOAD_BW_128_TRC	  := $(addsuffix load_bw_128.trc,${LOAD_BW_FIG_DIRS})

STORE_BW_2		  := $(addsuffix store_bw_2.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_2_TRC	  := $(addsuffix store_bw_2.trc,${STORE_BW_FIG_DIRS})

STORE_BW_4		  := $(addsuffix store_bw_4.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_4_TRC	  := $(addsuffix store_bw_4.trc,${STORE_BW_FIG_DIRS})

STORE_BW_8		  := $(addsuffix store_bw_8.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_8_TRC	  := $(addsuffix store_bw_8.trc,${STORE_BW_FIG_DIRS})

STORE_BW_16	  	  := $(addsuffix store_bw_16.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_16_TRC	  := $(addsuffix store_bw_16.trc,${STORE_BW_FIG_DIRS})

STORE_BW_32	  	  := $(addsuffix store_bw_32.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_32_TRC	  := $(addsuffix store_bw_32.trc,${STORE_BW_FIG_DIRS})

STORE_BW_64	  	  := $(addsuffix store_bw_64.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_64_TRC	  := $(addsuffix store_bw_64.trc,${STORE_BW_FIG_DIRS})

STORE_BW_128	  := $(addsuffix store_bw_128.pdf,${STORE_BW_FIG_DIRS})
STORE_BW_128_TRC  := $(addsuffix store_bw_128.trc,${STORE_BW_FIG_DIRS})

# --------------- Variable definitions based on the pattern rule ---------------
# Second set of variable names/definitions. This one is formed based on the
#	pattern rule where the information is taken from the file path of the target.

# Example file path : rv32gc-ilp32-gcc/printf/nproc-2/

# Splitting up the file path into individual components
# $* - Pattern rule from which the file path will be determined from
DIRNAME_SPLIT1 = $(subst -,${space},$*)
DIRNAME_SPLIT2 = $(subst /,${space}, $(DIRNAME_SPLIT1))
# The example at this point would then be : rv32gc ilp32 gcc printf nproc 2
ISA 		= $(word 1, $(DIRNAME_SPLIT2)) # rv32gc
ABI			= $(word 2, $(DIRNAME_SPLIT2)) # ilp32
COMPILER 	= $(word 3, $(DIRNAME_SPLIT2)) # gcc
FNAME 		= $(word 4, $(DIRNAME_SPLIT2)) # printf
# The 5th word is nproc; no information we can take from this
N_PROC 		= $(word 6, $(DIRNAME_SPLIT2)) # 2

# If there is a '32' present in rv__, set XLEN to it. 
#	Else set it to 64 if that is present
XLEN 	 	= $(findstring 32, $(ISA))
XLEN 	 	?= $(findstring 64, $(ISA))

#	Commands used within recipes that require these variables taken from the
#		file path using the pattern rule
CC = riscv$(XLEN)-unknown-elf-$(COMPILER)	# Compilation command
OBJDUMP = ${RISCV}/bin/riscv$(XLEN)-unknown-elf-objdump
SIZE 	= ${RISCV}/bin/riscv$(XLEN)-unknown-elf-size 

SPIKE 	= ${RISCV}/bin/spike

# 	Default compiler flags
# More information : https://gcc.gnu.org/onlinedocs/gcc/RISC-V-Options.html

# ISA Configuration
#	- Determines the base instruction set and the additional extensions
#	- Uses:
#		- Spike - Determines what instructions and registers to have available
#		when simulating,
#		- Script analysis - Determines what instructions and registers to look
#		at when parsing.
CFLAGS = -march=$(ISA)

# ABI - Application Binary Interface
#	- Specifies the integer and floating-point calling convention
#	- Determines the bit sizes of the types
CFLAGS += -mabi=${ABI}

# mcmodel -  Code model
#	- Determines the code model (medlow/medium-low or medany/medium-any)
#	- Used to determine conditions for the address range where the program
#	and it's statically defifned symbols can be placed
CFLAGS += -mcmodel=medany

# freestanding program
#	- Tells the compiler that the standard library may not exist and so
#	it should be a freestanding/bare-metal program (does not load an external
#	module)
#	- Needed so that we can use functions provided by syscalls.c that use
#	the HTIF (Host/Target Interface) which the Spike simulator will be
#	able to simulate
CFLAGS += -ffreestanding

# Static libraries
#	- Forces program to use static libraries
#	- Needed to allow us to specifically state what libraries we want present in
#	the program
CFLAGS += -static
CFLAGS += -lgcc

# No standard libraries
#	- Tells the program to not use the standard system startup files or libraries 
#	when linking
#	- Allows us to use our own linker scripts
CFLAGS += -nostdlib

# No standard startup files
#	- Tells the compiler to not use the standard system startup files when linking
#	- Allows us to use our own startup files which work unlike the standard ones
#	in setting up the system so that it can be simulated in Spike properly.
CFLAGS += -nostartfiles

LDFLAGS = -T${LINKER_SCRIPT}

#	Testing
print_all: TRACES
	@echo TRACES
	@echo ${TRACES}
	@echo
	@echo MAIN_TRACES
	@echo ${MAIN_TRACES}
	@echo
	@echo NPROC_DIRS
	@echo ${NPROC_DIRS}
	@echo
	@echo FNAME_DIRS
	@echo ${FNAME_DIRS}
	@echo
	@echo HISTOGRAMS
	@echo ${HISTOGRAMS}
	@echo
	@echo OBJECTS
	@echo ${OBJECTS}
	@echo
	@echo EXECUTABLES
	@echo ${EXECUTABLES}
	@echo
	@echo DISASSEMBLIES
	@echo ${DISASSEMBLIES}
	@echo
	@echo MAIN_DISASSEMBLIES
	@echo ${MAIN_DISASSEMBLIES}

TRACES:
	mkdir -p ${FNAME_DIRS}

# Details of all recipes can be found in /doc/dependencies.md

#	------------------------------ DIRECTORIES --------------------------------
# Targets to form all needed directories in one to avoid having multiple separate 
#	mkdir commands that flood the command line.

# .PHONY: NPROC_DIRS
NPROC_DIRS:
	@echo Making all NPROC_DIRS
	mkdir -p ${NPROC_DIRS}

# .PHONY: FNAME_DIRS
FNAME_DIRS:
	@echo Making all FNAME_DIRS
	mkdir -p ${FNAME_DIRS}

# .PHONY: COMMON_DIRS
COMMON_DIRS:
	@echo Making all COMMON_DIRS
	mkdir -p ${COMMON_DIRS}

# .PHONY: FIGURE_DIRS
FIGURE_DIRS:
	@echo Making all FIGURE_DIRS
	mkdir -p ${FIGURE_DIRS}

LOAD_BW_FIG_DIRS:
	mkdir -p ${LOAD_BW_FIG_DIRS}

STORE_BW_FIG_DIRS:
	mkdir -p ${STORE_BW_FIG_DIRS}

# ----------------------------------- BUILD -----------------------------------
# Compilation targets (executables and object files)
.PHONY: build
build: ${EXECUTABLES}

# Executable
# example $* = % = rv32gc-ilp32-gcc/simple_add/nproc-1/..
${BUILD_DIR}/%/testcase.elf: \
	${BUILD_DIR}/%/testcase.o \
	${BUILD_DIR}/%/../common/syscalls.o \
	${SRC_COMMON_DIR}/entry.S \
	| FNAME_DIRS

	${CC} $^ $(CFLAGS) ${INCLUDES} ${LDFLAGS} -o $@

# First dependency of this recipe is dependent on information in the file path of the
#	recipe which must be expanded into $*. Secondary expansion is used to then access
#	the file path through the pattern rule which after parsing a bit and adding the 
#	necessary prefixes and suffixes, forms the file path for the input test case (whose
#	name is present in the file path)
# Input program object file
.SECONDEXPANSION:
${BUILD_DIR}/%/testcase.o: \
	$$(addsuffix .c,$$(addprefix ${SRC_DIR}/,$$(word 2, $$(subst /, ,$$*)))) \
	| FNAME_DIRS

	${CC} $(CFLAGS) ${INCLUDES} -c $^ -o $@

# syscalls object file
${BUILD_DIR}/%/../common/syscalls.o: ${SRC_COMMON_DIR}/syscalls.c | COMMON_DIRS
	${CC} $(CFLAGS) ${INCLUDES} -w -c $< -o $@

# --------------------------------- ASSEMBLY ----------------------------------
# Assembly file produced using the '-S' flag with the compilation line; currently
#	not being used for any analysis

.PHONY: assembly
assembly: ${ASSEMBLIES}

# Secondary expansion use explained in the testcase.o recipe
.SECONDEXPANSION:
${BUILD_DIR}/%/testcase.S: \
	$$(addsuffix .c,$$(addprefix ${SRC_DIR}/,$$(word 2, $$(subst /, ,$$*)))) \
	| FNAME_DIRS

	${CC} $(CFLAGS) ${INCLUDES} -S $^ -o $@

# --------------- INSTRUCTION TRACE, DISASSEMBLY and HISTOGRAM ---------------

# Instruction trace
.PHONY: sim
sim: ${TRACES}

${BUILD_DIR}/%/testcase.trc: ${BUILD_DIR}/%/../testcase.elf | NPROC_DIRS
	${SPIKE} -p${N_PROC} -l --isa=$(ISA) $< 2> $@

# Disassembly
.PHONY: disassembly
disassembly: ${DISASSEMBLIES}

${BUILD_DIR}/%/testcase.dasm: ${BUILD_DIR}/%/testcase.elf | FNAME_DIRS
	${OBJDUMP} -S -D $< > $@

# Histogram produced using the '-g' flag
.PHONY: histogram
histogram: ${HISTOGRAMS}

${BUILD_DIR}/%/testcase.hst: ${BUILD_DIR}/%/testcase.elf | FNAME_DIRS
	${SPIKE} -g --isa=$(ISA) $< 2> $@

# Reduced instruction trace that only covers the region where we
#	enter and leave main
.PHONY: extract_main
extract_main: ${MAIN_TRACES}

${BUILD_DIR}/%/main.trc: ${BUILD_DIR}/%/../main.dasm ${BUILD_DIR}/%/testcase.trc | NPROC_DIRS
	$(eval START_ADDRESS = $(shell cat $< | head -n1 | awk '{print $$1;}'))
	$(eval END_ADDRESS = $(shell cat $< | tail -n1 | awk '{print $$1;}' | tr -d ':'))
	sed -n '/${START_ADDRESS}/,/${END_ADDRESS}/p' ${BUILD_DIR}/$*/testcase.trc > $@

# Reduced disassembly - only covering the main function to then parse the start and end
#	address from
${BUILD_DIR}/%/../main.dasm: ${BUILD_DIR}/%/../testcase.dasm | NPROC_DIRS
	sed -n '/<main>:/,/ret/p' $< > $@

# ------------------------ INSTRUCTION TRACE ANALYSIS -------------------------
# 			------------------------ BANDWIDTH -------------------------

# make bandwidth - forms all possible figures
.PHONY: display_bandwidth
display_bandwidth: display_load_bw_all display_store_bw_all

# 			   ----------------------- LOAD ------------------------
# make display_load_bw_all - forms all load_bw figures
.PHONY: display_load_bw_all
display_load_bw_all: load_bw_small \
	load_bw_medium \
	load_bw_large

# make load_bw_small - Only produces figures using small window sizes
.PHONY: load_bw_small
load_bw_small : display_load_bw_2 display_load_bw_4

# make load_bw_medium - Only produces figures using medium window sizes
.PHONY: load_bw_medium
load_bw_medium : display_load_bw_8 display_load_bw_16 display_load_bw_32

# make load_bw_large - Only produces figures using large window sizes
.PHONY: load_bw_large
load_bw_large : display_load_bw_64 display_load_bw_128

# make load_bw_x - forms all bw figures for a moving window of size x for powers
#	of 2 in the range [2, 128]
.PHONY: display_load_bw_2
display_load_bw_2 : ${LOAD_BW_2} ${LOAD_BW_2_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_2.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_2.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=2 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_load_bw_4
display_load_bw_4 : ${LOAD_BW_4} ${LOAD_BW_4_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_4.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_4.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=4 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_load_bw_8
display_load_bw_8 : ${LOAD_BW_8} ${LOAD_BW_8_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_8.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_8.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=8 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_load_bw_16
display_load_bw_16 : ${LOAD_BW_16} ${LOAD_BW_16_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_16.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_16.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=16 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_load_bw_32
display_load_bw_32 : ${LOAD_BW_32} ${LOAD_BW_32_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_32.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_32.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=32 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_load_bw_64
display_load_bw_64 : ${LOAD_BW_64} ${LOAD_BW_64_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_64.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_64.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=64 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_load_bw_128
display_load_bw_128 : ${LOAD_BW_128} ${LOAD_BW_128_TRC}

${BUILD_DIR}/%/figures/bw/load/load_bw_128.pdf \
${BUILD_DIR}/%/figures/bw/load/load_bw_128.trc \
	: ${BUILD_DIR}/%/load-byte-stream.trc | LOAD_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=128 \
	< $< > $(addsuffix .trc,$(basename $@))

# 			  ----------------------- STORE ------------------------
# make display_store_bw_all - forms all store_bw figures
.PHONY: display_store_bw_all
display_store_bw_all: display_store_bw_small \
	display_store_bw_medium \
	display_store_bw_large

.PHONY: display_store_bw_small
display_store_bw_small : display_store_bw_2 display_store_bw_4

.PHONY: display_store_bw_medium
display_store_bw_medium : display_store_bw_8 display_store_bw_16 display_store_bw_32

.PHONY: display_store_bw_large
display_store_bw_large : display_store_bw_64 display_store_bw_128

# make display_store_bw_x - forms all bw figures for a moving window of size x
.PHONY: display_store_bw_2
display_store_bw_2 : ${STORE_BW_2} ${STORE_BW_2_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_2.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_2.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS

	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=2 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_store_bw_4
display_store_bw_4 : ${STORE_BW_4} ${STORE_BW_4_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_4.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_4.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS
	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=4 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_store_bw_8
display_store_bw_8 : ${STORE_BW_8} ${STORE_BW_8_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_8.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_8.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS
	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=8 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_store_bw_16
display_store_bw_16 : ${STORE_BW_16} ${STORE_BW_16_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_16.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_16.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS
	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=16 < \
	$< > $(addsuffix .trc,$(basename $@))

.PHONY: display_store_bw_32
display_store_bw_32 : ${STORE_BW_32} ${STORE_BW_32_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_32.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_32.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS
	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=32 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_store_bw_64
display_store_bw_64 : ${STORE_BW_64} ${STORE_BW_64_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_64.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_64.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS
	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=64 \
	< $< > $(addsuffix .trc,$(basename $@))

.PHONY: display_store_bw_128
display_store_bw_128 : ${STORE_BW_128} ${STORE_BW_128_TRC}
${BUILD_DIR}/%/figures/bw/store/store_bw_128.pdf \
${BUILD_DIR}/%/figures/bw/store/store_bw_128.trc \
	: ${BUILD_DIR}/%/store-byte-stream.trc | STORE_BW_FIG_DIRS
	python3 scripts/bandwidth/display_bw.py \
	--img=$(addsuffix .pdf,$(basename $@)) --window=128 \
	< $< > $(addsuffix .trc,$(basename $@))

# 	Recipes for solely producing the bandwidth streams
# make bandwidth_streams - forms all possible bandwidth stream traces
.PHONY: bandwidth_streams
bandwidth: load_bw_streams store_bw_streams

.PHONY: load_bw_streams
load_bw_streams: ${LOAD_BYTE_STREAMS}
${BUILD_DIR}/%/load-byte-stream.trc: ${BUILD_DIR}/%/main.trc
	python3 scripts/bandwidth/load_bw/load_bw.py --isa=$(ISA) < $< > $@

.PHONY: store_bw_streams
store_bw_streams: ${STORE_BYTE_STREAMS}
${BUILD_DIR}/%/store-byte-stream.trc: ${BUILD_DIR}/%/main.trc
	python3 scripts/bandwidth/store_bw/store_bw.py --isa=$(ISA) < $< > $@

# 			-------------- INSTRUCTION PATTERN DETECTION ---------------
# .PHONY: 

# ----------------------------------- CLEAN ------------------------------------
.PHONY: clean
clean:
	rm -r ${BUILD_DIR}

###################################################################################
# # Spike with GDB
# .PHONY: debug
# debug:
# 	@echo "-------------------  Starting Debugging  -------------------"
# 	@${SPIKE} -d -p${N_PROC} --isa=$(ISA) $(TARGET).elf

# # Extra option for simulating cache
# .PHONY: build-sim-cache
# build-sim-cache: $(TARGET).elf
# #  --hartids=<a,b,...>   Explicitly specify hartids, default is 0,1,...
# #  --ic=<S>:<W>:<B>      Instantiate a cache model with S sets,
# #  --dc=<S>:<W>:<B>        W ways, and B-byte blocks (with S and
# #  --l2=<S>:<W>:<B>        B both powers of 2).
# #	DEFAULT lowRISC values
# #  --ic=64:4:8      Instantiate a cache model with S sets,
# #  --dc=64:4:8        W ways, and B-byte blocks (with S and
# #  --l2=256:8:8        B both powers of 2).
# 	@echo ""
# 	@echo "-------------  Build done, starting simulation  -------------"
# 	@${SPIKE} -p${N_PROC} --isa=$(ISA) --ic=64:4:8 --dc=64:4:8 --l2=256:8:8 $(TARGET).elf
