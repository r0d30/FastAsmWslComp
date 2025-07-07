# LayerCake - Projet Assembleur Linux

Structure de projet classique pour l'assembleur Linux x86-64.

## Structure
```
LayerCake/
├── src/           # Code source
│   ├── main.asm   # Programme principal
│   └── helloworld.asm
├── build/         # Fichiers compilés
└── Makefile       # Compilation
```

## Compilation
```bash
make        # Compiler
make run    # Compiler et exécuter avec limites de ressources
# Sous Windows : utilisez WSL -> wsl make run
make clean  # Nettoyer
make debug  # Compiler avec symboles debug
```

## Prérequis
- NASM
- LD (linker)
- Linux x86-64
- Windows : WSL Bash pour exécuter les commandes make
- Sous Windows (WSL) : pour rendre un script exécutable, utilisez le chemin Unix, exemple :
  ```powershell
  wsl chmod +x /mnt/c/Users/<votre_user>/Desktop/code/asm/LayerCake/limits.sh
  wsl make run
  ```
