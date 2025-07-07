#!/bin/bash

# limits.sh - Script pour définir les limites de ressources

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Configuration des limites de sécurité${NC}"

# Définir les limites
set_limits() {
    echo "Définition des limites de ressources..."
    
    # Mémoire virtuelle : 10MB
    ulimit -v 10240
    echo "✓ Mémoire virtuelle limitée à 10MB"
    
    # Nombre de processus : 10
    ulimit -u 10
    echo "✓ Nombre de processus limité à 10"
    
    # Temps CPU : 5 secondes
    ulimit -t 5
    echo "✓ Temps CPU limité à 5 secondes"
    
    # Taille des fichiers : 1MB
    #ulimit -f 1024
    #echo "✓ Taille des fichiers limitée à 1MB"
    
    # Taille de la pile : 1MB
    ulimit -s 1024
    echo "✓ Taille de la pile limitée à 1MB"
    
    # Nombre de fichiers ouverts : 10
    ulimit -n 10
    echo "✓ Nombre de fichiers ouverts limité à 10"
}

# Afficher les limites actuelles
show_limits() {
    echo -e "\n${YELLOW}Limites actuelles :${NC}"
    echo "Mémoire virtuelle : $(ulimit -v) KB"
    echo "Processus : $(ulimit -u)"
    echo "Temps CPU : $(ulimit -t) secondes"
    echo "Taille fichiers : $(ulimit -f) blocs"
    echo "Taille pile : $(ulimit -s) KB"
    echo "Fichiers ouverts : $(ulimit -n)"
}

# Tester un programme avec limites
test_with_limits() {
    local program=$1
    echo -e "\n${GREEN}Test de $program avec limites${NC}"
    
    # Exécuter avec timeout et monitoring
    timeout 10s /usr/bin/time -v $program 2>&1 | {
        while read line; do
            case $line in
                *"Maximum resident set size"*)
                    echo "RAM max utilisée : $line"
                    ;;
                *"User time"*)
                    echo "Temps utilisateur : $line"
                    ;;
                *"System time"*)
                    echo "Temps système : $line"
                    ;;
                *"Percent of CPU"*)
                    echo "Utilisation CPU : $line"
                    ;;
            esac
        done
    }
}

# Script principal
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
            echo "Usage: $0 test <programme>"
            exit 1
        fi
        set_limits
        test_with_limits $2
        ;;
    *)
        echo "Usage: $0 {set|show|test <programme>}"
        echo "  set   - Définir les limites"
        echo "  show  - Afficher les limites"
        echo "  test  - Tester un programme avec limites"
        exit 1
        ;;
esac
