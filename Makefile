# Makefile for Linux assembly project
AS = nasm
ASFLAGS = -f elf64
LD = ld
CC = gcc

# =============================================================================
# CONFIGURABLE VARIABLES (can be overridden in make command)
# =============================================================================

# Program name (without extension)
PROG_NAME ?= program

# Program extension (supported formats only)
PROG_EXT ?= elf

# Extension validation
VALID_EXTS := elf bin out
ifeq ($(filter $(PROG_EXT),$(VALID_EXTS)),)
    $(error Extension '$(PROG_EXT)' not supported. Valid extensions: $(VALID_EXTS))
endif

# Specific object order (default: automatic order)
OBJ_ORDER ?= 

# Resource limits (ulimit) - set "none" to disable
ULIMIT_VIRTUAL ?= 10240    # Virtual memory (kB)
ULIMIT_PROCESSES ?= 10     # Number of processes
ULIMIT_TIME ?= 5           # CPU time (seconds)
ULIMIT_FILESIZE ?= 1024    # File size (kB)

# Additional compilation flags
EXTRA_ASFLAGS ?= 
EXTRA_CCFLAGS ?= 

# Custom build directory
CUSTOM_BUILDDIR ?= 

# =============================================================================
# INTERNAL CONFIGURATION
# =============================================================================

# Directories
SRCDIR = src
BUILDDIR = $(if $(CUSTOM_BUILDDIR),$(CUSTOM_BUILDDIR),build)

# Files
# Dynamically generate object linking order
SCRIPT = scripts/gen_link_order.sh
# Limits management script
LIMIT_SCRIPT = scripts/limits.sh
# Objects directory and object list generation
OBJDIR = $(BUILDDIR)/obj

# Final target name construction
TARGET = $(BUILDDIR)/$(PROG_NAME).$(PROG_EXT)

# Object order management
ifeq ($(OBJ_ORDER),)
	# Default automatic order
	DYN := $(shell bash $(SCRIPT) $(SRCDIR) $(BUILDDIR) $(OBJDIR))
	OBJECTS := $(if $(DYN),$(DYN),$(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(wildcard $(SRCDIR)/*.asm)))
else
	# Specific order defined
	OBJECTS := $(addprefix $(OBJDIR)/,$(addsuffix .o,$(OBJ_ORDER)))
endif

# Final compilation flags
FINAL_ASFLAGS = $(ASFLAGS) $(EXTRA_ASFLAGS)
FINAL_CCFLAGS = $(EXTRA_CCFLAGS)

# Specify bash as shell
SHELL := /bin/bash

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to apply ulimits
define apply_ulimits
	@echo "-- Applying resource limits --"
	$(if $(filter-out none,$(ULIMIT_VIRTUAL)),@echo "  Virtual memory: $(ULIMIT_VIRTUAL) kB"; ulimit -v $(ULIMIT_VIRTUAL);,@echo "  Virtual memory: unlimited")
	$(if $(filter-out none,$(ULIMIT_PROCESSES)),@echo "  Processes: $(ULIMIT_PROCESSES)"; ulimit -u $(ULIMIT_PROCESSES);,@echo "  Processes: unlimited")
	$(if $(filter-out none,$(ULIMIT_TIME)),@echo "  CPU time: $(ULIMIT_TIME) sec"; ulimit -t $(ULIMIT_TIME);,@echo "  CPU time: unlimited")
	$(if $(filter-out none,$(ULIMIT_FILESIZE)),@echo "  File size: $(ULIMIT_FILESIZE) kB"; ulimit -f $(ULIMIT_FILESIZE);,@echo "  File size: unlimited")
endef

# Function to display configuration
define show_config
	@echo "=== Compilation Configuration ==="
	@echo "Program: $(PROG_NAME).$(PROG_EXT)"
	@echo "Build directory: $(BUILDDIR)"
	@echo "Object order: $(if $(OBJ_ORDER),$(OBJ_ORDER),automatic)"
	@echo "ASM flags: $(FINAL_ASFLAGS)"
	@echo "CC flags: $(FINAL_CCFLAGS)"
	@echo "Limits - VM:$(ULIMIT_VIRTUAL) Proc:$(ULIMIT_PROCESSES) Time:$(ULIMIT_TIME) File:$(ULIMIT_FILESIZE)"
	@echo "====================================="
endef

# =============================================================================
# MAIN TARGETS
# =============================================================================
all: build

# Clean build directory (removes everything)
clean:
	rm -rf $(BUILDDIR)

# Build ELF (purge build first, pause for display)
build: clean
	$(call show_config)
	@sleep 0.5
	@mkdir -p $(BUILDDIR)
	@$(MAKE) $(TARGET) FINAL_ASFLAGS="$(FINAL_ASFLAGS)" FINAL_CCFLAGS="$(FINAL_CCFLAGS)"

$(TARGET): $(OBJECTS)
	@echo "-- Linking --"
	$(CC) -no-pie -nostartfiles $(FINAL_CCFLAGS) $(OBJECTS) -o $(TARGET)
	@echo "-- Program created: $(TARGET) --"

# Compile .asm files to .o (obj directory)
$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(OBJDIR)
	@echo "Assembling: $< -> $@"
	$(AS) $(FINAL_ASFLAGS) $< -o $@

# Execute: apply ulimits, measure resources, without GDB
run: 
	$(call show_config)
	@$(MAKE) clean build FINAL_ASFLAGS="$(FINAL_ASFLAGS) -g -F dwarf"
	$(call apply_ulimits)
	@echo "-- Running program (measurement) --"
	/usr/bin/time -v $(TARGET)
	@echo "-- Execution completed --"

# Execute in debug TUI mode (recompile with DWARF symbols, start at _start and show registers)
.PHONY: run_debug
run_debug:
	$(call show_config)
	@$(MAKE) clean build FINAL_ASFLAGS="$(FINAL_ASFLAGS) -g -F dwarf"
	$(call apply_ulimits)
	@echo "-- Running program (measurement) --"
	/usr/bin/time -v $(TARGET)
	@echo "-- Launching GDB in TUI mode, run and show registers --"
	gdb -q \
	    -ex "layout split" \
	    -ex "layout regs" \
	    -ex "run" \
	    -ex "info registers" \
	    $(TARGET)

# build_run: build then execute once
build_run: build run

# build_run_debug: debug compilation and execution
.PHONY: build_run_debug
build_run_debug: run_debug

# Monitor temporary files created
.PHONY: all build run run_debug build_run build_run_debug clean

# =============================================================================
# HELP AND DOCUMENTATION
# =============================================================================

help:
	@echo "=== FastAsmWslComp Makefile - Help ==="
	@echo ""
	@echo "Available targets:"
	@echo "  all          - Compile the program (default)"
	@echo "  build        - Compile the program"
	@echo "  run          - Compile and execute (without GDB)"
	@echo "  run_debug    - Compile and execute with GDB TUI"
	@echo "  clean        - Clean build directory"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Configurable variables:"
	@echo "  PROG_NAME=name           - Program name (default: program)"
	@echo "  PROG_EXT=ext            - Extension (default: elf, valid: elf|bin|out)"
	@echo "  OBJ_ORDER='obj1 obj2'   - Object order (default: auto)"
	@echo "  ULIMIT_VIRTUAL=kb       - Virtual memory limit (default: 10240)"
	@echo "  ULIMIT_PROCESSES=nb     - Process limit (default: 10)"
	@echo "  ULIMIT_TIME=sec         - CPU time limit (default: 5)"
	@echo "  ULIMIT_FILESIZE=kb      - File size limit (default: 1024)"
	@echo "  EXTRA_ASFLAGS=flags     - Additional assembler flags"
	@echo "  EXTRA_CCFLAGS=flags     - Additional compiler flags"
	@echo "  CUSTOM_BUILDDIR=dir     - Custom build directory"
	@echo ""
	@echo "Usage examples:"
	@echo "  make run PROG_NAME=test"
	@echo "  make run PROG_NAME=kernel PROG_EXT=bin"
	@echo "  make run OBJ_ORDER='math_add math_sub math_mul math_div'"
	@echo "  make run ULIMIT_VIRTUAL=none ULIMIT_TIME=10"
	@echo ""
