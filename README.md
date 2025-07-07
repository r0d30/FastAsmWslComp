# FastAsmWslComp - Advanced Assembly Compilation Framework

A sophisticated Linux x86-64 assembly compilation framework with automatic dependency management, resource limits, and integrated development tools.

## Features

- **Automatic dependency management**: Intelligent linking order based on symbol analysis
- **Configurable resource limits**: Protection against infinite loops and excessive memory usage
- **Multi-format support**: ELF, BIN, OUT
- **Integrated debugging**: GDB support with TUI interface
- **Flexible configuration**: Command-line customizable variables
- **WSL compatibility**: Optimized for Windows development

## Project Structure

```
FastAsmWslComp/
├── src/                    # Assembly source code (.asm)
├── build/                  # Compiled files
│   ├── obj/               # Object files (.o)
│   └── program.elf        # Final executable
├── scripts/               # Utility scripts
│   ├── gen_link_order.sh  # Automatic linking order generation
│   └── limits.sh          # Resource limits management
├── Makefile               # Advanced compilation configuration
└── README.md              # Documentation
```

## Installation and Prerequisites

### System Requirements
- **NASM** (Netwide Assembler)
- **GCC** (GNU Compiler Collection)
- **GDB** (GNU Debugger) - for debugging
- **Linux x86-64** or **WSL** on Windows

### Installation on Ubuntu/Debian
```bash
sudo apt update
sudo apt install nasm gcc gdb build-essential
```

### WSL Configuration (Windows)
```powershell
# Enable scripts in WSL
wsl chmod +x /mnt/c/path/to/FastAsmWslComp/scripts/*.sh
```

## Usage

### Basic Commands
```bash
# Simple compilation
make build

# Compilation and execution with resource limits
make run

# Debugging with GDB in TUI mode
make run_debug

# Clean build directory
make clean

# Show complete help
make help
```

### Advanced Configuration
```bash
# Compile with custom name
make run PROG_NAME=my_program

# Change output format
make run PROG_NAME=kernel PROG_EXT=bin

# Manual linking order
make run OBJ_ORDER='math_add math_sub math_mul math_div'

# Adjust resource limits
make run ULIMIT_VIRTUAL=20480 ULIMIT_TIME=10

# Disable limits
make run ULIMIT_VIRTUAL=none ULIMIT_TIME=none
```

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROG_NAME` | `program` | Final program name |
| `PROG_EXT` | `elf` | Extension (elf, bin, out) |
| `OBJ_ORDER` | `auto` | Object linking order |
| `ULIMIT_VIRTUAL` | `10240` | Virtual memory limit (kB) |
| `ULIMIT_PROCESSES` | `10` | Process number limit |
| `ULIMIT_TIME` | `5` | CPU time limit (seconds) |
| `ULIMIT_FILESIZE` | `1024` | File size limit (kB) |
| `EXTRA_ASFLAGS` | - | Additional assembler flags |
| `EXTRA_CCFLAGS` | - | Additional compiler flags |
| `CUSTOM_BUILDDIR` | `build` | Custom build directory |

## Advanced Features

### Automatic Dependency Management
The system automatically analyzes `global` symbols and `call` instructions to determine optimal object linking order.

### Resource Limits
Built-in protection against:
- Excessive memory usage
- Infinite loops (CPU time limit)
- Excessive process creation
- Oversized files

### Integrated Debugging
Debug mode with automatic GDB TUI:
- Split interface (code + assembly)
- Register display
- DWARF debug symbols

## Development

### Assembly File Structure
```asm
section .data
    ; Initialized data

section .bss
    ; Uninitialized data

section .text
    global _start       ; Entry point
    global my_function  ; Exported function

_start:
    ; Main code
    call my_function
    ; Exit code
    mov eax, 60
    mov edi, 0
    syscall

my_function:
    ; Implementation
    ret
```

### Best Practices
- Use `global` to export symbols
- Follow Linux x86-64 calling conventions
- Document your functions with comments
- Test with resource limits enabled

## Debugging

### Useful GDB Commands
```bash
# In GDB TUI
(gdb) layout split    # Code + assembly view
(gdb) layout regs     # Display registers
(gdb) stepi           # Step instruction
(gdb) info registers  # Register state
(gdb) x/10i $rip      # Disassemble around RIP
```

## Usage Examples

### Example 1: Simple Program
```bash
# Create src/hello.asm
make run PROG_NAME=hello
```

### Example 2: Multi-file Project
```bash
# With main.asm, math.asm, utils.asm
make run PROG_NAME=calculator OBJ_ORDER='main math utils'
```

### Example 3: Development with Debugging
```bash
make run_debug PROG_NAME=test ULIMIT_TIME=30
```

## Contributing

1. Fork the project
2. Create a branch for your feature
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Versions

- **v1.1**: Current version with advanced features
- **v1.0**: Initial version with basic features
- **latest**: Active development version

---

*Framework developed for learning and advanced development in Linux x86-64 assembly*
