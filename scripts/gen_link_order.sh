#!/usr/bin/env bash
# gen_link_order.sh - Generates object linking order based on assembly dependencies
# Usage: bash gen_link_order.sh <srcdir> <builddir> <objdir>

srcdir=$1
builddir=$2
objdir=$3

tmp=$(mktemp)

# Map defined symbols -> file
declare -A def
for f in "$srcdir"/*.asm; do
  base=$(basename "$f" .asm)
  grep -P '^\s*global\s+' "$f" | sed -E 's/^\s*global\s+//' | while read sym; do
    def[$sym]=$base
  done
done

# Generate pairs for tsort
for f in "$srcdir"/*.asm; do
  base=$(basename "$f" .asm)
  # analyze calls
  grep -oP 'call\s+\K\w+' "$f" | while read sym; do
    dep=${def[$sym]}
    if [[ -n "$dep" ]]; then
      echo "$base $dep" >> "$tmp"
    fi
  done
done

# ensure all modules are listed
for f in "$srcdir"/*.asm; do
  echo "$(basename "$f" .asm)" >> "$tmp"
done

# topological sort
order=$(tsort "$tmp")
rm -f "$tmp"

# print object list with path
while read mod; do
  echo "$objdir/$mod.o"
done <<< "$order"
