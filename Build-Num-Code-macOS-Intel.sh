#!/usr/bin/env bash
set -euo pipefail
python3 Num-Code-Compiler.py Num-Code.txt Num-Code.bin
python3 Num-Code-Compiler.py Num-Code-Strings.txt Num-Code-Strings.bin
mkdir -p modules
clang -O3 -dynamiclib modules/Num-Code-Module-128.c -o modules/Num-Code-Module-128.dylib
nasm -f macho64 Num-Code-Runtime-macOS-Intel.asm -o Num-Code-Runtime-macOS-Intel.o
clang -arch x86_64 -Wl,-no_pie Num-Code-Runtime-macOS-Intel.o Num-Code-External-Loader.c -o Num-Code
./Num-Code
