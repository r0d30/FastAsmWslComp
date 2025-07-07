#!/usr/bin/env bash
# gen_link_order.sh - Génère l'ordre de liaison des objets selon dépendances d'assembleur
# Usage: bash gen_link_order.sh <srcdir> <builddir> <objdir>

srcdir=$1
builddir=$2
objdir=$3

tmp=$(mktemp)

# Mapper symboles définis -> fichier
declare -A def
for f in "$srcdir"/*.asm; do
  base=$(basename "$f" .asm)
  grep -P '^\s*global\s+' "$f" | sed -E 's/^\s*global\s+//' | while read sym; do
    def[$sym]=$base
  done
done

# Générer paires pour tsort
for f in "$srcdir"/*.asm; do
  base=$(basename "$f" .asm)
  # analyser les appels
  grep -oP 'call\s+\K\w+' "$f" | while read sym; do
    dep=${def[$sym]}
    if [[ -n "$dep" ]]; then
      echo "$base $dep" >> "$tmp"
    fi
  done
done

# assurer que tous les modules sont listés
for f in "$srcdir"/*.asm; do
  echo "$(basename "$f" .asm)" >> "$tmp"
done

# topological sort
order=$(tsort "$tmp")
rm -f "$tmp"

# imprimer la liste d'objets avec chemin
while read mod; do
  echo "$objdir/$mod.o"
done <<< "$order"
