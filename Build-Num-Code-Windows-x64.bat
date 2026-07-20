@echo off
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 Num-Code-Compiler.py Num-Code.txt Num-Code.bin
  if errorlevel 1 exit /b 1
  py -3 Num-Code-Compiler.py Num-Code-Strings.txt Num-Code-Strings.bin
) else (
  python Num-Code-Compiler.py Num-Code.txt Num-Code.bin
  if errorlevel 1 exit /b 1
  python Num-Code-Compiler.py Num-Code-Strings.txt Num-Code-Strings.bin
)
if errorlevel 1 exit /b 1
if not exist modules mkdir modules
gcc -O3 -shared modules\Num-Code-Module-128.c -o modules\Num-Code-Module-128.dll
if errorlevel 1 exit /b 1
nasm -f win64 Num-Code-Runtime-Windows-x64.asm -o Num-Code-Runtime-Windows-x64.obj
if errorlevel 1 exit /b 1
gcc -O3 Num-Code-Runtime-Windows-x64.obj Num-Code-External-Loader.c -o Num-Code.exe -lkernel32
if errorlevel 1 exit /b 1
Num-Code.exe
