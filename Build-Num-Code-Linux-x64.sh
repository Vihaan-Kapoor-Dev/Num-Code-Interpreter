#!/usr/bin/env bash
set -euo pipefail
python3 Num-Code-Compiler.py Num-Code.txt Num-Code.bin
python3 Num-Code-Compiler.py Num-Code-Strings.txt Num-Code-Strings.bin
mkdir -p modules
gcc -O3 -fPIC -shared modules/Num-Code-Module-128.c -o modules/Num-Code-Module-128.so
nasm -f elf64 Num-Code-Runtime-Linux-x64.asm -o Num-Code-Runtime-Linux-x64.o
gcc -O3 -fno-stack-protector -fno-pie -no-pie Num-Code-Runtime-Linux-x64.o Num-Code-External-Loader.c -ldl -o Num-Code
./Num-Code
