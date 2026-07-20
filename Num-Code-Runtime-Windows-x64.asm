bits 64
default rel

%ifndef SAFE_MODE
%define SAFE_MODE 0
%endif

%define OP_IMPORT 20
%define OP_CALL0 21
%define OP_CALL1 22
%define OP_CALL2 23
%define MAX_OPCODE 23

%macro NEXT 0
    movzx eax, byte [rsi]
    add rsi, 8
%if SAFE_MODE
    cmp eax, MAX_OPCODE
    ja op_bad
%endif
    jmp [r15 + rax*8]
%endmacro

section .rdata
align 8
program:
    incbin "Num-Code.bin"
string_pool:
    incbin "Num-Code-Strings.bin"
newline db 10
align 8
dispatch_table:
    dq op_halt,op_seti,op_addi,op_subi,op_muli,op_divi,op_powi
    dq op_print_reg,op_print_imm,op_print_str,op_jmp,op_jz,op_jnz
    dq op_jlt8,op_jgt8,op_jeq8,op_add_jlt_reg,op_sub_jnz,op_movr,op_addr
    dq op_import,op_call0,op_call1,op_call2

section .bss
align 16
variables resd 26
number_buffer resb 16
stdout_handle resq 1
written_count resd 1
stdin_handle resq 1
read_count resd 1
loaded_modules resd 1
random_state resd 1
input_buffer resb 64

section .text
global main
extern GetStdHandle
extern WriteFile
extern ExitProcess
extern ReadFile
extern GetTickCount64
extern num_code_external_import
extern num_code_external_call0
extern num_code_external_call1
extern num_code_external_call2

main:
    sub rsp, 40
    mov ecx, -11
    call GetStdHandle
    mov [stdout_handle], rax
    mov ecx, -10
    call GetStdHandle
    mov [stdin_handle], rax
    mov dword [random_state], 0xA341316C
    lea rsi, [program]
    lea r15, [dispatch_table]
    lea rbx, [variables]
    NEXT

op_halt:
    xor ecx, ecx
    call ExitProcess

op_seti:
    movzx ecx, byte [rsi-7]
    mov eax, [rsi-4]
    mov [rbx+rcx*4], eax
    NEXT

op_addi:
    movzx ecx, byte [rsi-7]
    mov eax, [rsi-4]
    add [rbx+rcx*4], eax
    NEXT

op_subi:
    movzx ecx, byte [rsi-7]
    mov eax, [rsi-4]
    sub [rbx+rcx*4], eax
    NEXT

op_muli:
    movzx ecx, byte [rsi-7]
    mov eax, [rbx+rcx*4]
    imul eax, [rsi-4]
    mov [rbx+rcx*4], eax
    NEXT

op_divi:
    mov eax, [rsi-4]
    test eax, eax
    jz op_divzero
    movzx ecx, byte [rsi-7]
    mov r8d, eax
    mov eax, [rbx+rcx*4]
    xor edx, edx
    div r8d
    mov [rbx+rcx*4], eax
    NEXT

op_powi:
    movzx ecx, byte [rsi-7]
    mov eax, [rbx+rcx*4]
    mov r8d, [rsi-4]
    mov edx, 1
.p:
    test r8d, r8d
    jz .done
    test r8b, 1
    jz .square
    imul edx, eax
.square:
    imul eax, eax
    shr r8d, 1
    jmp .p
.done:
    mov [rbx+rcx*4], edx
    NEXT

op_print_reg:
    movzx ecx, byte [rsi-7]
    mov eax, [rbx+rcx*4]
    call write_u32_newline
    NEXT

op_print_imm:
    mov eax, [rsi-4]
    call write_u32_newline
    NEXT

op_print_str:
    movzx edx, byte [rsi-7]
    movsxd rax, dword [rsi-4]
    lea r8, [string_pool+rax]
    mov r14, rsi
    mov rsi, r8
    call platform_write
    lea rsi, [newline]
    mov edx, 1
    call platform_write
    mov rsi, r14
    NEXT

op_jmp:
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
    NEXT

op_jz:
    movzx ecx, byte [rsi-7]
    cmp dword [rbx+rcx*4], 0
    jne .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jnz:
    movzx ecx, byte [rsi-7]
    cmp dword [rbx+rcx*4], 0
    je .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jlt8:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    cmp [rbx+rcx*4], edx
    jae .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jgt8:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    cmp [rbx+rcx*4], edx
    jbe .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jeq8:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    cmp [rbx+rcx*4], edx
    jne .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_add_jlt_reg:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    movzx r8d, byte [rsi-5]
    mov eax, [rbx+rcx*4]
    add eax, r8d
    mov [rbx+rcx*4], eax
    cmp eax, [rbx+rdx*4]
    jae .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_sub_jnz:
    movzx ecx, byte [rsi-7]
    movzx eax, byte [rsi-6]
    sub [rbx+rcx*4], eax
    jz .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_movr:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    mov eax, [rbx+rdx*4]
    mov [rbx+rcx*4], eax
    NEXT

op_addr:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    mov eax, [rbx+rdx*4]
    add [rbx+rcx*4], eax
    NEXT

op_import:
    movzx ecx, byte [rsi-7]
    cmp ecx, 255
    je .all
    cmp ecx, 128
    jae .external
    cmp ecx, 1
    jb op_bad_module
    cmp ecx, 4
    ja op_bad_module
    bts dword [loaded_modules], ecx
    NEXT
.external:
    cmp ecx, 254
    ja op_bad_module
    call num_code_external_import
    test eax, eax
    jnz op_external_error
    NEXT
.all:
    mov dword [loaded_modules], 0x1E
    NEXT

op_call0:
    movzx r12d, byte [rsi-7]
    cmp r12d, 25
    ja op_bad_register
    movzx r10d, byte [rsi-6]
    movzx r11d, byte [rsi-5]
    cmp r10d, 128
    jae .external
    cmp r10d, 1
    jb op_bad_module
    cmp r10d, 4
    ja op_bad_module
    bt dword [loaded_modules], r10d
    jnc op_not_imported
    cmp r10d, 2
    je .random
    cmp r10d, 3
    je .time
    cmp r10d, 4
    je .input
    jmp op_bad_function
.external:
    cmp r10d, 254
    ja op_bad_module
    mov ecx, r10d
    mov edx, r11d
    call num_code_external_call0
    mov rdx, rax
    shr rdx, 32
    test edx, edx
    jnz op_external_call_error
    mov [rbx+r12*4], eax
    NEXT
.random:
    cmp r11d, 1
    jne op_bad_function
    call random_next
    mov [rbx+r12*4], eax
    NEXT
.time:
    cmp r11d, 1
    jne op_bad_function
    call time_millis
    mov [rbx+r12*4], eax
    NEXT
.input:
    cmp r11d, 1
    jne op_bad_function
    call read_u32
    mov [rbx+r12*4], eax
    NEXT

op_call1:
    movzx r12d, byte [rsi-7]
    cmp r12d, 25
    ja op_bad_register
    movzx r10d, byte [rsi-6]
    movzx r11d, byte [rsi-5]
    movzx r13d, byte [rsi-4]
    cmp r13d, 25
    ja op_bad_register
    cmp r10d, 128
    jae .external
    cmp r10d, 1
    jb op_bad_module
    cmp r10d, 4
    ja op_bad_module
    bt dword [loaded_modules], r10d
    jnc op_not_imported
    mov eax, [rbx+r13*4]
    cmp r10d, 1
    je .math
    cmp r10d, 2
    je .random
    jmp op_bad_function
.external:
    cmp r10d, 254
    ja op_bad_module
    mov ecx, r10d
    mov edx, r11d
    mov r8d, [rbx+r13*4]
    call num_code_external_call1
    mov rdx, rax
    shr rdx, 32
    test edx, edx
    jnz op_external_call_error
    mov [rbx+r12*4], eax
    NEXT
.math:
    cmp r11d, 1
    je .sqrt
    cmp r11d, 5
    je .popcount
    jmp op_bad_function
.sqrt:
    call math_isqrt
    mov [rbx+r12*4], eax
    NEXT
.popcount:
    call math_popcount
    mov [rbx+r12*4], eax
    NEXT
.random:
    cmp r11d, 3
    jne op_bad_function
    test eax, eax
    jnz .seed_ok
    mov eax, 0xA341316C
.seed_ok:
    mov [random_state], eax
    mov [rbx+r12*4], eax
    NEXT

op_call2:
    movzx r12d, byte [rsi-7]
    cmp r12d, 25
    ja op_bad_register
    movzx r10d, byte [rsi-6]
    movzx r11d, byte [rsi-5]
    movzx r13d, byte [rsi-4]
    movzx r14d, byte [rsi-3]
    cmp r13d, 25
    ja op_bad_register
    cmp r14d, 25
    ja op_bad_register
    cmp r10d, 128
    jae .external
    cmp r10d, 1
    jb op_bad_module
    cmp r10d, 4
    ja op_bad_module
    bt dword [loaded_modules], r10d
    jnc op_not_imported
    cmp r10d, 1
    je .math
    cmp r10d, 2
    je .random
    jmp op_bad_function
.external:
    cmp r10d, 254
    ja op_bad_module
    mov ecx, r10d
    mov edx, r11d
    mov r8d, [rbx+r13*4]
    mov r9d, [rbx+r14*4]
    call num_code_external_call2
    mov rdx, rax
    shr rdx, 32
    test edx, edx
    jnz op_external_call_error
    mov [rbx+r12*4], eax
    NEXT
.math:
    cmp r11d, 2
    je .gcd
    cmp r11d, 3
    je .min
    cmp r11d, 4
    je .max
    jmp op_bad_function
.gcd:
    mov eax, [rbx+r13*4]
    mov edx, [rbx+r14*4]
    call math_gcd
    mov [rbx+r12*4], eax
    NEXT
.min:
    mov eax, [rbx+r13*4]
    mov edx, [rbx+r14*4]
    cmp eax, edx
    cmova eax, edx
    mov [rbx+r12*4], eax
    NEXT
.max:
    mov eax, [rbx+r13*4]
    mov edx, [rbx+r14*4]
    cmp eax, edx
    cmovb eax, edx
    mov [rbx+r12*4], eax
    NEXT
.random:
    cmp r11d, 2
    jne op_bad_function
    mov r10d, [rbx+r13*4]
    mov r11d, [rbx+r14*4]
    cmp r11d, r10d
    jbe .range_low
    call random_next
    mov ecx, r11d
    sub ecx, r10d
    xor edx, edx
    div ecx
    lea eax, [rdx+r10]
    mov [rbx+r12*4], eax
    NEXT
.range_low:
    mov [rbx+r12*4], r10d
    NEXT

op_external_call_error:
    mov eax, edx
op_external_error:
    add eax, 20
    mov ecx, eax
    call ExitProcess

random_next:
    mov eax, [random_state]
    test eax, eax
    jnz .go
    mov eax, 0xA341316C
.go:
    mov edx, eax
    shl edx, 13
    xor eax, edx
    mov edx, eax
    shr edx, 17
    xor eax, edx
    mov edx, eax
    shl edx, 5
    xor eax, edx
    mov [random_state], eax
    ret

math_isqrt:
    mov r8d, eax
    xor eax, eax
    mov edx, 0x40000000
.align:
    cmp edx, r8d
    jbe .loop
    shr edx, 2
    jmp .align
.loop:
    test edx, edx
    jz .done
    lea ecx, [eax+edx]
    cmp r8d, ecx
    jb .no_sub
    sub r8d, ecx
    shr eax, 1
    add eax, edx
    jmp .next
.no_sub:
    shr eax, 1
.next:
    shr edx, 2
    jmp .loop
.done:
    ret

math_popcount:
    xor edx, edx
.loop:
    test eax, eax
    jz .done
    lea ecx, [eax-1]
    and eax, ecx
    inc edx
    jmp .loop
.done:
    mov eax, edx
    ret

math_gcd:
.loop:
    test edx, edx
    jz .done
    xor ecx, ecx
    mov ecx, edx
    xor edx, edx
    div ecx
    mov eax, ecx
    jmp .loop
.done:
    ret
time_millis:
    sub rsp, 40
    call GetTickCount64
    add rsp, 40
    ret

read_u32:
    sub rsp, 40
    mov rcx, [stdin_handle]
    lea rdx, [input_buffer]
    mov r8d, 64
    lea r9, [read_count]
    mov qword [rsp+32], 0
    call ReadFile
    test eax, eax
    jz .error
    mov ecx, [read_count]
    add rsp, 40
    test ecx, ecx
    jz .zero
    lea r10, [input_buffer]
    xor eax, eax
    xor r8d, r8d
.loop:
    movzx edx, byte [r10]
    inc r10
    cmp edx, 48
    jb .not_digit
    cmp edx, 57
    ja .not_digit
    imul eax, eax, 10
    sub edx, 48
    add eax, edx
    mov r8d, 1
    dec ecx
    jnz .loop
    ret
.not_digit:
    test r8d, r8d
    jnz .done
    dec ecx
    jnz .loop
.zero:
    xor eax, eax
.done:
    ret
.error:
    mov ecx, 14
    call ExitProcess

write_u32_newline:
    push rsi
    lea rsi, [number_buffer+15]
    mov byte [rsi], 10
    mov r10d, 1
    mov ecx, 10
.c:
    xor edx, edx
    div ecx
    dec rsi
    add dl, 48
    mov [rsi], dl
    inc r10d
    test eax, eax
    jnz .c
    mov edx, r10d
    call platform_write
    pop rsi
    ret

platform_write:
    sub rsp, 40
    mov r8d, edx
    mov rdx, rsi
    mov rcx, [stdout_handle]
    lea r9, [written_count]
    mov qword [rsp+32], 0
    call WriteFile
    add rsp, 40
    ret

op_divzero:
    mov ecx, 3
    call ExitProcess

op_bad:
    mov ecx, 2
    call ExitProcess


op_bad_module:
    mov ecx, 10
    call ExitProcess

op_not_imported:
    mov ecx, 11
    call ExitProcess

op_bad_function:
    mov ecx, 12
    call ExitProcess

op_bad_register:
    mov ecx, 13
    call ExitProcess
