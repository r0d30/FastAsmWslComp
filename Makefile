# Makefile pour projet assembleur Linux
AS = nasm
ASFLAGS = -f elf64
LD = ld
CC = gcc

# =============================================================================
# VARIABLES CONFIGURABLES (peuvent être surchargées dans la commande make)
# =============================================================================

# Nom du programme (sans extension)
PROG_NAME ?= program

# Extension du programme (formats supportés uniquement)
PROG_EXT ?= elf

# Validation de l'extension
VALID_EXTS := elf bin out
ifeq ($(filter $(PROG_EXT),$(VALID_EXTS)),)
    $(error Extension '$(PROG_EXT)' non supportée. Extensions valides: $(VALID_EXTS))
endif

# Ordre spécifique des objets (par défaut : ordre automatique)
OBJ_ORDER ?= 

# Limites de ressources (ulimit) - mettre "none" pour désactiver
ULIMIT_VIRTUAL ?= 10240    # Mémoire virtuelle (kB)
ULIMIT_PROCESSES ?= 10     # Nombre de processus
ULIMIT_TIME ?= 5           # Temps CPU (secondes)
ULIMIT_FILESIZE ?= 1024    # Taille des fichiers (kB)

# Flags de compilation supplémentaires
EXTRA_ASFLAGS ?= 
EXTRA_CCFLAGS ?= 

# Répertoire de build personnalisé
CUSTOM_BUILDDIR ?= 

# =============================================================================
# CONFIGURATION INTERNE
# =============================================================================

# Répertoires
SRCDIR = src
BUILDDIR = $(if $(CUSTOM_BUILDDIR),$(CUSTOM_BUILDDIR),build)

# Fichiers
# Générer dynamiquement l'ordre de liaison des objets
SCRIPT = scripts/gen_link_order.sh
# Script de gestion des limites
LIMIT_SCRIPT = scripts/limits.sh
# Répertoire des objets et génération de la liste d'objets à lier
OBJDIR = $(BUILDDIR)/obj

# Construction du nom de target final
TARGET = $(BUILDDIR)/$(PROG_NAME).$(PROG_EXT)

# Gestion de l'ordre des objets
ifeq ($(OBJ_ORDER),)
	# Ordre automatique par défaut
	DYN := $(shell bash $(SCRIPT) $(SRCDIR) $(BUILDDIR) $(OBJDIR))
	OBJECTS := $(if $(DYN),$(DYN),$(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(wildcard $(SRCDIR)/*.asm)))
else
	# Ordre spécifique défini
	OBJECTS := $(addprefix $(OBJDIR)/,$(addsuffix .o,$(OBJ_ORDER)))
endif

# Flags de compilation finaux
FINAL_ASFLAGS = $(ASFLAGS) $(EXTRA_ASFLAGS)
FINAL_CCFLAGS = $(EXTRA_CCFLAGS)

# Spécifier l'utilisation de bash comme shell
SHELL := /bin/bash

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

# Fonction pour appliquer les ulimits
define apply_ulimits
	@echo "-- Application des limites de ressources --"
	$(if $(filter-out none,$(ULIMIT_VIRTUAL)),@echo "  Mémoire virtuelle: $(ULIMIT_VIRTUAL) kB"; ulimit -v $(ULIMIT_VIRTUAL);,@echo "  Mémoire virtuelle: non limitée")
	$(if $(filter-out none,$(ULIMIT_PROCESSES)),@echo "  Processus: $(ULIMIT_PROCESSES)"; ulimit -u $(ULIMIT_PROCESSES);,@echo "  Processus: non limité")
	$(if $(filter-out none,$(ULIMIT_TIME)),@echo "  Temps CPU: $(ULIMIT_TIME) sec"; ulimit -t $(ULIMIT_TIME);,@echo "  Temps CPU: non limité")
	$(if $(filter-out none,$(ULIMIT_FILESIZE)),@echo "  Taille fichiers: $(ULIMIT_FILESIZE) kB"; ulimit -f $(ULIMIT_FILESIZE);,@echo "  Taille fichiers: non limitée")
endef

# Fonction pour afficher la configuration
define show_config
	@echo "=== Configuration de compilation ==="
	@echo "Programme: $(PROG_NAME).$(PROG_EXT)"
	@echo "Répertoire build: $(BUILDDIR)"
	@echo "Ordre des objets: $(if $(OBJ_ORDER),$(OBJ_ORDER),automatique)"
	@echo "Flags ASM: $(FINAL_ASFLAGS)"
	@echo "Flags CC: $(FINAL_CCFLAGS)"
	@echo "Limites - VM:$(ULIMIT_VIRTUAL) Proc:$(ULIMIT_PROCESSES) Time:$(ULIMIT_TIME) File:$(ULIMIT_FILESIZE)"
	@echo "====================================="
endef

# =============================================================================
# CIBLES PRINCIPALES
# =============================================================================
all: build

# Nettoyer le répertoire build (supprime tout)
clean:
	rm -rf $(BUILDDIR)

# Construction de l'ELF (purge build avant, pause pour affichage)
build: clean
	$(call show_config)
	@sleep 0.5
	@mkdir -p $(BUILDDIR)
	@$(MAKE) $(TARGET) FINAL_ASFLAGS="$(FINAL_ASFLAGS)" FINAL_CCFLAGS="$(FINAL_CCFLAGS)"

$(TARGET): $(OBJECTS)
	@echo "-- Édition de liens --"
	$(CC) -no-pie -nostartfiles $(FINAL_CCFLAGS) $(OBJECTS) -o $(TARGET)
	@echo "-- Programme créé: $(TARGET) --"

# Compiler les fichiers .asm en .o (répertoire obj)
$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(OBJDIR)
	@echo "Assemblage: $< -> $@"
	$(AS) $(FINAL_ASFLAGS) $< -o $@

# Exécuter : appliquer ulimits, mesurer ressources, sans GDB
run: 
	$(call show_config)
	@$(MAKE) clean build FINAL_ASFLAGS="$(FINAL_ASFLAGS) -g -F dwarf"
	$(call apply_ulimits)
	@echo "-- Exécution du programme (mesure) --"
	/usr/bin/time -v $(TARGET)
	@echo "-- Exécution terminée --"

# Exécuter en mode debug TUI (recompile avec symboles DWARF, démarre à _start et affiche registres)
.PHONY: run_debug
run_debug:
	$(call show_config)
	@$(MAKE) clean build FINAL_ASFLAGS="$(FINAL_ASFLAGS) -g -F dwarf"
	$(call apply_ulimits)
	@echo "-- Exécution du programme (mesure) --"
	/usr/bin/time -v $(TARGET)
	@echo "-- Lancement de GDB en mode TUI, run et show registers --"
	gdb -q \
	    -ex "layout split" \
	    -ex "layout regs" \
	    -ex "run" \
	    -ex "info registers" \
	    $(TARGET)

# build_run : construction puis exécution unique
build_run: build run

# build_run_debug : compilation debug et exécution
.PHONY: build_run_debug
build_run_debug: run_debug

# Surveillance des fichiers temporaires créés
.PHONY: all build run run_debug build_run build_run_debug clean

# =============================================================================
# AIDE ET DOCUMENTATION
# =============================================================================

help:
	@echo "=== LayerCake Makefile - Aide ==="
	@echo ""
	@echo "Cibles disponibles:"
	@echo "  all          - Compile le programme (défaut)"
	@echo "  build        - Compile le programme"
	@echo "  run          - Compile et exécute (sans GDB)"
	@echo "  run_debug    - Compile et exécute avec GDB TUI"
	@echo "  clean        - Nettoie le répertoire build"
	@echo "  help         - Affiche cette aide"
	@echo ""
	@echo "Variables configurables:"
	@echo "  PROG_NAME=nom           - Nom du programme (défaut: program)"
	@echo "  PROG_EXT=ext            - Extension (défaut: elf, valides: elf|bin|out)"
	@echo "  OBJ_ORDER='obj1 obj2'   - Ordre des objets (défaut: auto)"
	@echo "  ULIMIT_VIRTUAL=kb       - Limite mémoire virtuelle (défaut: 10240)"
	@echo "  ULIMIT_PROCESSES=nb     - Limite processus (défaut: 10)"
	@echo "  ULIMIT_TIME=sec         - Limite temps CPU (défaut: 5)"
	@echo "  ULIMIT_FILESIZE=kb      - Limite taille fichiers (défaut: 1024)"
	@echo "  EXTRA_ASFLAGS=flags     - Flags assembleur supplémentaires"
	@echo "  EXTRA_CCFLAGS=flags     - Flags compilateur supplémentaires"
	@echo "  CUSTOM_BUILDDIR=dir     - Répertoire de build personnalisé"
	@echo ""
	@echo "Exemples d'utilisation:"
	@echo "  make run PROG_NAME=test"
	@echo "  make run PROG_NAME=kernel PROG_EXT=bin"
	@echo "  make run OBJ_ORDER='math_add math_sub math_mul math_div'"
	@echo "  make run ULIMIT_VIRTUAL=none ULIMIT_TIME=10"
	@echo ""
