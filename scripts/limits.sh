#!/bin/bash

# limits.sh - Script to define resource limits

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Configuring security limits${NC}"

# Define limits
set_limits() {
    echo "Setting resource limits..."
    
    # Virtual memory: 10MB
    ulimit -v 10240
    echo "✓ Virtual memory limited to 10MB"
    
    # Number of processes: 10
    ulimit -u 10
    echo "✓ Number of processes limited to 10"
    
    # CPU time: 5 seconds
    ulimit -t 5
    echo "✓ CPU time limited to 5 seconds"
    
    # File size: 1MB
    #ulimit -f 1024
    #echo "✓ File size limited to 1MB"
    
    # Stack size: 1MB
    ulimit -s 1024
    echo "✓ Stack size limited to 1MB"
    
    # Number of open files: 10
    ulimit -n 10
    echo "✓ Number of open files limited to 10"
}

# Display current limits
show_limits() {
    echo -e "\n${YELLOW}Current limits:${NC}"
    echo "Virtual memory: $(ulimit -v) KB"
    echo "Processes: $(ulimit -u)"
    echo "CPU time: $(ulimit -t) seconds"
    echo "File size: $(ulimit -f) blocks"
    echo "Stack size: $(ulimit -s) KB"
    echo "Open files: $(ulimit -n)"
}

# Test a program with limits
test_with_limits() {
    local program=$1
    echo -e "\n${GREEN}Testing $program with limits${NC}"
    
    # Execute with timeout and monitoring
    timeout 10s /usr/bin/time -v $program 2>&1 | {
        while read line; do
            case $line in
                *"Maximum resident set size"*)
                    echo "Max RAM used: $line"
                    ;;
                *"User time"*)
                    echo "User time: $line"
                    ;;
                *"System time"*)
                    echo "System time: $line"
                    ;;
                *"Percent of CPU"*)
                    echo "CPU usage: $line"
                    ;;
            esac
        done
    }
}

# Main script
case $1 in
    "set")
        set_limits
        show_limits
        ;;
    "show")
        show_limits
        ;;
    "test")
        if [ -z "$2" ]; then
            echo "Usage: $0 test <program>"
            exit 1
        fi
        set_limits
        test_with_limits $2
        ;;
    *)
        echo "Usage: $0 {set|show|test <program>}"
        echo "  set   - Set limits"
        echo "  show  - Display limits"
        echo "  test  - Test a program with limits"
        exit 1
        ;;
esac
