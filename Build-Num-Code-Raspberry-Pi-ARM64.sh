#!/usr/bin/env bash
set -euo pipefail
python3 Num-Code-Compiler.py Num-Code.txt Num-Code.bin
python3 Num-Code-Compiler.py Num-Code-Strings.txt Num-Code-Strings.bin
mkdir -p modules
gcc -O3 -fPIC -shared modules/Num-Code-Module-128.c -o modules/Num-Code-Module-128.so
gcc -c Num-Code-Runtime-Raspberry-Pi-ARM64.s -o Num-Code-Runtime-Raspberry-Pi-ARM64.o
gcc -O3 -no-pie Num-Code-Runtime-Raspberry-Pi-ARM64.o Num-Code-External-Loader.c -ldl -o Num-Code
./Num-Code
