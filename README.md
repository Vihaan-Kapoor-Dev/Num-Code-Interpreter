# Num-Code-Interpreter
I made a lang called Num Code it only uses numbers to code. It is made for all Linux, Windows MacOS and More.
It took me like 5 years to make this lol and 2 more to more it github ready lol.
# Numeric VM v2 — Complete Simple Guide

## 1. How programs are written

Every instruction contains exactly **8 numbers**:

```text
OPCODE A B C IMM0 IMM1 IMM2 IMM3
```

Example:

```text
1 0 0 0 10 0 0 0
```

This means:

```text
A = 10
```

The first number is the command. The other numbers are its inputs.

---

# 2. Variables

Numeric VM has 26 variables:

```text
0  = A
1  = B
2  = C
3  = D
4  = E
...
25 = Z
```

Example:

```text
1 2 0 0 50 0 0 0
```

This means:

```text
C = 50
```

---

# 3. Command numbers

```text
0  = Stop

1  = Set variable
2  = Add number
3  = Subtract number
4  = Multiply by number
5  = Divide by number
6  = Power

7  = Print variable
8  = Print number
9  = Print text

10 = Jump
11 = Jump if variable is zero
12 = Jump if variable is not zero
13 = Jump if variable is less than a number
14 = Jump if variable is greater than a number
15 = Jump if variable equals a number

16 = Add, compare, and loop
17 = Subtract and loop

18 = Copy variable
19 = Add one variable to another

20 = Import module
21 = Call function with zero inputs
22 = Call function with one input
23 = Call function with two inputs
```

---

# 4. Basic math

## Set A to 10

```text
1 0 0 0 10 0 0 0
```

## Add 5 to A

```text
2 0 0 0 5 0 0 0
```

## Subtract 3 from A

```text
3 0 0 0 3 0 0 0
```

## Multiply A by 4

```text
4 0 0 0 4 0 0 0
```

## Divide A by 2

```text
5 0 0 0 2 0 0 0
```

## Raise A to power 3

```text
6 0 0 0 3 0 0 0
```

---

# 5. Printing

## Print variable A

```text
7 0 0 0 0 0 0 0
```

## Print the number 100

```text
8 0 0 0 100 0 0 0
```

## Print text

Text is placed inside:

```text
strings_v2.txt
```

For example, store:

```text
72 101 108 108 111
```

Those numbers represent:

```text
Hello
```

Then print five characters starting at offset zero:

```text
9 5 0 0 0 0 0 0
```

---

# 6. Complete basic program

Put this inside `program_v2.txt`:

```text
1 0 0 0 10 0 0 0
2 0 0 0 5 0 0 0
7 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

Meaning:

```text
A = 10
A = A + 5
Print A
Stop
```

Output:

```text
15
```

---

# 7. Values larger than 255

The final four numbers form one 32-bit value:

```text
IMM0 IMM1 IMM2 IMM3
```

They use little-endian order.

For values smaller than 256:

```text
100 = 100 0 0 0
```

For `1000`:

```text
1000 = 232 3 0 0
```

Example:

```text
1 0 0 0 232 3 0 0
```

This sets:

```text
A = 1000
```

---

# 8. Copying and adding variables

## Copy A into B

```text
18 1 0 0 0 0 0 0
```

Meaning:

```text
B = A
```

## Add B to A

```text
19 0 1 0 0 0 0 0
```

Meaning:

```text
A = A + B
```

---

# 9. Fast loop

This program counts from zero to ten:

```text
1 0 0 0 0 0 0 0
1 1 0 0 10 0 0 0
16 0 1 1 255 255 255 255
7 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

Meaning:

```text
A = 0
B = 10

A = A + 1
Repeat while A < B

Print A
Stop
```

Output:

```text
10
```

The four `255` values mean jump backward by one instruction.

---

# 10. Built-in imports

Built-in module numbers:

```text
1   = Math
2   = Random
3   = Time
4   = Input
255 = Import every built-in module
```

Import format:

```text
20 MODULE 0 0 0 0 0 0
```

Import Math:

```text
20 1 0 0 0 0 0 0
```

Import everything:

```text
20 255 0 0 0 0 0 0
```

---

# 11. Calling imported functions

## Function with zero inputs

```text
21 DEST MODULE FUNCTION 0 0 0 0
```

## Function with one input

```text
22 DEST MODULE FUNCTION ARG 0 0 0
```

## Function with two inputs

```text
23 DEST MODULE FUNCTION ARG1 ARG2 0 0
```

`DEST` is the variable where the answer is stored.

---

# 12. Math module

Math is module:

```text
1
```

Functions:

```text
1 = Square root
2 = Greatest common divisor
3 = Minimum
4 = Maximum
5 = Count binary 1-bits
```

## Square root example

```text
20 1 0 0 0 0 0 0
1 0 0 0 81 0 0 0
22 1 1 1 0 0 0 0
7 1 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

Meaning:

```text
Import Math
A = 81
B = Math function 1 using A
Print B
Stop
```

Output:

```text
9
```

## GCD example

```text
20 1 0 0 0 0 0 0
1 0 0 0 48 0 0 0
1 1 0 0 18 0 0 0
23 2 1 2 0 1 0 0
7 2 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

Meaning:

```text
A = 48
B = 18
C = Math.gcd(A, B)
Print C
```

Output:

```text
6
```

---

# 13. Random module

Random is module:

```text
2
```

Functions:

```text
1 = Next random number
2 = Random number in a range
3 = Set random seed
```

## Generate a random number

```text
20 2 0 0 0 0 0 0
21 0 2 1 0 0 0 0
7 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

Meaning:

```text
Import Random
A = Random function 1
Print A
```

---

# 14. Time module

Time is module:

```text
3
```

Function:

```text
1 = Current milliseconds
```

Example:

```text
20 3 0 0 0 0 0 0
21 0 3 1 0 0 0 0
7 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

---

# 15. Input module

Input is module:

```text
4
```

Function:

```text
1 = Read a number
```

Example:

```text
20 4 0 0 0 0 0 0
21 0 4 1 0 0 0 0
7 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

This waits for the user to enter a number, stores it in A, and prints it.

---

# 16. External libraries

External module IDs are:

```text
128 through 254
```

Each external module must have a matching filename.

For module `128`:

```text
Windows:
modules/nvm_module_128.dll

Linux:
modules/nvm_module_128.so

Raspberry Pi:
modules/nvm_module_128.so

macOS:
modules/nvm_module_128.dylib
```

---

# 17. Importing an external library

```text
20 128 0 0 0 0 0 0
```

This loads external module `128`.

The runtime caches the library after it is loaded.

---

# 18. External function calls

## No inputs

```text
21 DEST 128 FUNCTION 0 0 0 0
```

## One input

```text
22 DEST 128 FUNCTION ARG 0 0 0
```

## Two inputs

```text
23 DEST 128 FUNCTION ARG1 ARG2 0 0
```

The external module must export one function named:

```text
nvm_module_call
```

Its exact interface is defined in `external_module.h`.

---

# 19. Example external module

The included `modules/example_module.c` contains:

```text
Function 1 = Double a number
Function 2 = Add two numbers
Function 3 = Return 42
```

These behaviors are implemented in the sample module.

## Call function 1

```text
20 128 0 0 0 0 0 0
1 0 0 0 21 0 0 0
22 1 128 1 0 0 0 0
7 1 0 0 0 0 0 0
0 0 0 0 0 0 0 0
```

Meaning:

```text
Import module 128
A = 21
B = module 128 function 1 using A
Print B
Stop
```

Output:

```text
42
```

This format matches the included external-library example.

---

# 20. Creating your own external module

Choose a number from:

```text
128 through 254
```

Create a C file such as:

```c
#include "../external_module.h"

NVM_EXPORT uint32_t nvm_module_call(
    uint32_t function_id,
    uint32_t argument_count,
    uint32_t argument0,
    uint32_t argument1,
    uint32_t *status
) {
    *status = 0;

    if (function_id == 1) {
        if (argument_count != 1) {
            *status = 2;
            return 0;
        }

        return argument0 * 10;
    }

    if (function_id == 2) {
        if (argument_count != 2) {
            *status = 2;
            return 0;
        }

        return argument0 + argument1;
    }

    *status = 1;
    return 0;
}
```

Function `1` multiplies one value by ten.

Function `2` adds two values.

Every external module must export the same `nvm_module_call` interface.

---

# 21. Compile an external module

## Windows

```bat
gcc -O3 -shared modules\example_module.c -o modules\nvm_module_128.dll
```

## Linux

```bash
gcc -O3 -fPIC -shared modules/example_module.c -o modules/nvm_module_128.so
```

## Raspberry Pi

```bash
gcc -O3 -fPIC -shared modules/example_module.c -o modules/nvm_module_128.so
```

## macOS

```bash
clang -O3 -dynamiclib modules/example_module.c -o modules/nvm_module_128.dylib
```

The module filename must match its numeric module ID.

---

# 22. Running on Windows

Requirements:

```text
Python
NASM
GCC or MinGW-w64
```

Extract the ZIP and open Command Prompt in the extracted folder.

Run:

```bat
build_v2_windows_x64.bat
```

The script:

```text
Converts the numeric text into binary
Compiles the external DLL
Assembles the VM
Links the executable
Runs the program
```

---

# 23. Running on Linux

Install requirements:

```bash
sudo apt update
sudo apt install python3 nasm gcc binutils
```

Open the extracted directory:

```bash
chmod +x build_v2_linux_x64.sh
./build_v2_linux_x64.sh
```

The script builds and runs:

```text
runtime_v2_linux_x64
```

---

# 24. Running on Intel macOS

Install Xcode command-line tools:

```bash
xcode-select --install
```

Install NASM if needed:

```bash
brew install nasm
```

Run:

```bash
chmod +x build_v2_macos_x64.sh
./build_v2_macos_x64.sh
```

---

# 25. Running on Apple Silicon macOS

For M1, M2, M3, M4, or newer Apple processors:

```bash
xcode-select --install
chmod +x build_v2_macos_arm64.sh
./build_v2_macos_arm64.sh
```

---

# 26. Running on Raspberry Pi

The Raspberry Pi version requires a 64-bit operating system.

Check:

```bash
uname -m
```

It should show:

```text
aarch64
```

Install requirements:

```bash
sudo apt update
sudo apt install python3 gcc binutils
```

Run:

```bash
chmod +x build_v2_raspberrypi_arm64.sh
./build_v2_raspberrypi_arm64.sh
```

---

# 27. Normal workflow

Every time you create a program:

```text
1. Open program_v2.txt
2. Replace it with your numeric instructions
3. Save the file
4. Run the build script for your machine
5. Read the output
```

For text:

```text
1. Put character numbers in strings_v2.txt
2. Use opcode 9 to print them
3. Rebuild the program
```

For external modules:

```text
1. Pick an ID from 128–254
2. Create the module source
3. Compile it as DLL, SO, or DYLIB
4. Put it in the modules folder
5. Import it using opcode 20
6. Call it using opcode 21, 22, or 23
```

---

# 28. Important limitations

Numeric VM currently:

```text
Uses unsigned 32-bit numbers
Has variables A through Z
Supports up to two function inputs
Requires rebuilding after changing program_v2.txt
Does not directly import Python packages
Does not directly import JavaScript packages
Does not directly import normal DLL/SO functions
Requires a wrapper using nvm_module_call
```

---

# 29. Security warning

Only use external libraries you trust.

A native `.dll`, `.so`, or `.dylib` can:

```text
Read and change files
Access memory
Use the network
Run operating-system commands
Damage or delete data
```

External modules run with the same permissions as the VM.

---

# 30. External-library errors

```text
21 = Invalid external module ID
22 = Library could not be loaded
23 = nvm_module_call was missing
24 = Module was called before import
25 = External module returned an error
```
