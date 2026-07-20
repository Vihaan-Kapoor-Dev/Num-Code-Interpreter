#!/usr/bin/env bash
set -euo pipefail
python3 Num-Code-Compiler.py Num-Code.txt Num-Code.bin
python3 Num-Code-Compiler.py Num-Code-Strings.txt Num-Code-Strings.bin
mkdir -p modules
clang -O3 -dynamiclib modules/Num-Code-Module-128.c -o modules/Num-Code-Module-128.dylib
clang -arch arm64 -c Num-Code-Runtime-macOS-Apple-Silicon.s -o Num-Code-Runtime-macOS-Apple-Silicon.o
clang -arch arm64 Num-Code-Runtime-macOS-Apple-Silicon.o Num-Code-External-Loader.c -o Num-Code
./Num-Code
