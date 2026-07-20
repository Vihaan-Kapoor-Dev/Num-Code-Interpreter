.equ MAX_OPCODE, 23

.macro NEXT
ldrb w0, [x19]
add x19, x19, #8
ldr x1, [x25, w0, uxtw #3]
br x1
.endm

.section __TEXT,__const
.p2align 3
program:
.incbin "Num-Code.bin"
string_pool:
.incbin "Num-Code-Strings.bin"
newline:
.byte 10
.p2align 3
dispatch_table:
.xword op_halt,op_seti,op_addi,op_subi,op_muli,op_divi,op_powi
.xword op_print_reg,op_print_imm,op_print_str,op_jmp,op_jz,op_jnz
.xword op_jlt8,op_jgt8,op_jeq8,op_add_jlt_reg,op_sub_jnz,op_movr,op_addr
.xword op_import,op_call0,op_call1,op_call2

.section __DATA,__bss
.p2align 4
variables:
.skip 104
number_buffer:
.skip 16
loaded_modules:
.skip 4
random_state:
.skip 4
timespec_buffer:
.skip 16
input_buffer:
.skip 64

.section __TEXT,__text
.p2align 2
.global _main
.extern _write
.extern _exit
.extern _clock_gettime
.extern _read
.extern _num_code_external_import
.extern _num_code_external_call0
.extern _num_code_external_call1
.extern _num_code_external_call2
_main:
adrp x19, program@PAGE
add x19, x19, program@PAGEOFF
adrp x20, variables@PAGE
add x20, x20, variables@PAGEOFF
adrp x25, dispatch_table@PAGE
add x25, x25, dispatch_table@PAGEOFF
adrp x21, loaded_modules@PAGE
add x21, x21, loaded_modules@PAGEOFF
adrp x22, random_state@PAGE
add x22, x22, random_state@PAGEOFF
adrp x23, timespec_buffer@PAGE
add x23, x23, timespec_buffer@PAGEOFF
adrp x24, input_buffer@PAGE
add x24, x24, input_buffer@PAGEOFF
movz w0, #0x316c
movk w0, #0xa341, lsl #16
str w0, [x22]
NEXT

op_halt:
mov w0, wzr
bl _exit
brk #0

op_seti:
ldurb w1, [x19, #-7]
ldur w0, [x19, #-4]
str w0, [x20, w1, uxtw #2]
NEXT

op_addi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
add w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_subi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
sub w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_muli:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
mul w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_divi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
cbz w2, op_divzero
ldr w0, [x20, w1, uxtw #2]
udiv w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_powi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
mov w3, #1
1:
cbz w2, 3f
tbz w2, #0, 2f
mul w3, w3, w0
2:
mul w0, w0, w0
lsr w2, w2, #1
b 1b
3:
str w3, [x20, w1, uxtw #2]
NEXT

op_print_reg:
ldurb w1, [x19, #-7]
ldr w0, [x20, w1, uxtw #2]
bl write_u32_newline
NEXT

op_print_imm:
ldur w0, [x19, #-4]
bl write_u32_newline
NEXT

op_print_str:
ldurb w2, [x19, #-7]
ldursw x3, [x19, #-4]
adrp x1, string_pool@PAGE
add x1, x1, string_pool@PAGEOFF
add x1, x1, x3
bl platform_write
adrp x1, newline@PAGE
add x1, x1, newline@PAGEOFF
mov x2, #1
bl platform_write
NEXT

op_jmp:
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
NEXT

op_jz:
ldurb w1, [x19, #-7]
ldr w0, [x20, w1, uxtw #2]
cbnz w0, 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jnz:
ldurb w1, [x19, #-7]
ldr w0, [x20, w1, uxtw #2]
cbz w0, 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jlt8:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
cmp w0, w2
b.hs 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jgt8:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
cmp w0, w2
b.ls 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jeq8:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
cmp w0, w2
b.ne 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_add_jlt_reg:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldurb w3, [x19, #-5]
ldr w0, [x20, w1, uxtw #2]
add w0, w0, w3
str w0, [x20, w1, uxtw #2]
ldr w4, [x20, w2, uxtw #2]
cmp w0, w4
b.hs 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_sub_jnz:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
subs w0, w0, w2
str w0, [x20, w1, uxtw #2]
b.eq 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_movr:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w2, uxtw #2]
str w0, [x20, w1, uxtw #2]
NEXT

op_addr:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
ldr w3, [x20, w2, uxtw #2]
add w0, w0, w3
str w0, [x20, w1, uxtw #2]
NEXT


op_import:
ldurb w10, [x19, #-7]
cmp w10, #255
b.eq 1f
cmp w10, #128
b.hs 2f
cmp w10, #1
b.lo op_bad_module
cmp w10, #4
b.hi op_bad_module
mov w2, #1
lsl w2, w2, w10
ldr w3, [x21]
orr w3, w3, w2
str w3, [x21]
NEXT
1:
mov w3, #30
str w3, [x21]
NEXT
2:
cmp w10, #254
b.hi op_bad_module
mov w0, w10
bl _num_code_external_import
cbnz w0, op_external_error
NEXT

op_call0:
ldurb w26, [x19, #-7]
cmp w26, #25
b.hi op_bad_register
ldurb w10, [x19, #-6]
ldurb w11, [x19, #-5]
cmp w10, #128
b.hs 4f
cmp w10, #1
b.lo op_bad_module
cmp w10, #4
b.hi op_bad_module
mov w4, #1
lsl w4, w4, w10
ldr w5, [x21]
tst w5, w4
b.eq op_not_imported
cmp w10, #2
b.eq 1f
cmp w10, #3
b.eq 2f
cmp w10, #4
b.eq 3f
b op_bad_function
1:
cmp w11, #1
b.ne op_bad_function
bl random_next
str w0, [x20, w26, uxtw #2]
NEXT
2:
cmp w11, #1
b.ne op_bad_function
bl time_millis
str w0, [x20, w26, uxtw #2]
NEXT
3:
cmp w11, #1
b.ne op_bad_function
bl read_u32
str w0, [x20, w26, uxtw #2]
NEXT
4:
cmp w10, #254
b.hi op_bad_module
mov w0, w10
mov w1, w11
bl _num_code_external_call0
lsr x1, x0, #32
cbnz w1, op_external_call_error
str w0, [x20, w26, uxtw #2]
NEXT

op_call1:
ldurb w26, [x19, #-7]
cmp w26, #25
b.hi op_bad_register
ldurb w10, [x19, #-6]
ldurb w11, [x19, #-5]
ldurb w8, [x19, #-4]
cmp w8, #25
b.hi op_bad_register
cmp w10, #128
b.hs 5f
cmp w10, #1
b.lo op_bad_module
cmp w10, #4
b.hi op_bad_module
mov w4, #1
lsl w4, w4, w10
ldr w5, [x21]
tst w5, w4
b.eq op_not_imported
ldr w0, [x20, w8, uxtw #2]
cmp w10, #1
b.eq 1f
cmp w10, #2
b.eq 4f
b op_bad_function
1:
cmp w11, #1
b.eq 2f
cmp w11, #5
b.eq 3f
b op_bad_function
2:
bl math_isqrt
str w0, [x20, w26, uxtw #2]
NEXT
3:
bl math_popcount
str w0, [x20, w26, uxtw #2]
NEXT
4:
cmp w11, #3
b.ne op_bad_function
cbnz w0, 6f
movz w0, #0x316c
movk w0, #0xa341, lsl #16
6:
str w0, [x22]
str w0, [x20, w26, uxtw #2]
NEXT
5:
cmp w10, #254
b.hi op_bad_module
mov w0, w10
mov w1, w11
ldr w2, [x20, w8, uxtw #2]
bl _num_code_external_call1
lsr x1, x0, #32
cbnz w1, op_external_call_error
str w0, [x20, w26, uxtw #2]
NEXT

op_call2:
ldurb w26, [x19, #-7]
cmp w26, #25
b.hi op_bad_register
ldurb w10, [x19, #-6]
ldurb w11, [x19, #-5]
ldurb w8, [x19, #-4]
ldurb w9, [x19, #-3]
cmp w8, #25
b.hi op_bad_register
cmp w9, #25
b.hi op_bad_register
cmp w10, #128
b.hs 6f
cmp w10, #1
b.lo op_bad_module
cmp w10, #4
b.hi op_bad_module
mov w4, #1
lsl w4, w4, w10
ldr w5, [x21]
tst w5, w4
b.eq op_not_imported
cmp w10, #1
b.eq 1f
cmp w10, #2
b.eq 5f
b op_bad_function
1:
cmp w11, #2
b.eq 2f
cmp w11, #3
b.eq 3f
cmp w11, #4
b.eq 4f
b op_bad_function
2:
ldr w0, [x20, w8, uxtw #2]
ldr w1, [x20, w9, uxtw #2]
bl math_gcd
str w0, [x20, w26, uxtw #2]
NEXT
3:
ldr w0, [x20, w8, uxtw #2]
ldr w1, [x20, w9, uxtw #2]
cmp w0, w1
csel w0, w0, w1, ls
str w0, [x20, w26, uxtw #2]
NEXT
4:
ldr w0, [x20, w8, uxtw #2]
ldr w1, [x20, w9, uxtw #2]
cmp w0, w1
csel w0, w0, w1, hs
str w0, [x20, w26, uxtw #2]
NEXT
5:
cmp w11, #2
b.ne op_bad_function
ldr w27, [x20, w8, uxtw #2]
ldr w28, [x20, w9, uxtw #2]
cmp w28, w27
b.ls 7f
bl random_next
sub w1, w28, w27
udiv w2, w0, w1
msub w2, w2, w1, w0
add w0, w2, w27
str w0, [x20, w26, uxtw #2]
NEXT
7:
str w27, [x20, w26, uxtw #2]
NEXT
6:
cmp w10, #254
b.hi op_bad_module
mov w0, w10
mov w1, w11
ldr w2, [x20, w8, uxtw #2]
ldr w3, [x20, w9, uxtw #2]
bl _num_code_external_call2
lsr x1, x0, #32
cbnz w1, op_external_call_error
str w0, [x20, w26, uxtw #2]
NEXT

op_external_call_error:
mov w0, w1
op_external_error:
add w0, w0, #20
bl _exit
brk #0

random_next:
ldr w0, [x22]
cbnz w0, 1f
movz w0, #0x316c
movk w0, #0xa341, lsl #16
1:
eor w0, w0, w0, lsl #13
eor w0, w0, w0, lsr #17
eor w0, w0, w0, lsl #5
str w0, [x22]
ret

math_isqrt:
mov w8, w0
mov w0, wzr
mov w2, #0x40000000
1:
cmp w2, w8
b.ls 2f
lsr w2, w2, #2
b 1b
2:
cbz w2, 5f
add w3, w0, w2
cmp w8, w3
b.lo 3f
sub w8, w8, w3
lsr w0, w0, #1
add w0, w0, w2
b 4f
3:
lsr w0, w0, #1
4:
lsr w2, w2, #2
b 2b
5:
ret

math_popcount:
mov w1, wzr
1:
cbz w0, 2f
sub w2, w0, #1
and w0, w0, w2
add w1, w1, #1
b 1b
2:
mov w0, w1
ret

math_gcd:
1:
cbz w1, 2f
udiv w2, w0, w1
msub w2, w2, w1, w0
mov w0, w1
mov w1, w2
b 1b
2:
ret

time_millis:
mov w0, #6
mov x1, x23
bl _clock_gettime
cbnz w0, op_platform_error
ldr x8, [x23]
mov x9, #1000
mul x8, x8, x9
ldr x10, [x23, #8]
movz x11, #0x4240
movk x11, #0xf, lsl #16
udiv x10, x10, x11
add x0, x8, x10
ret

read_u32:
mov x0, #0
mov x1, x24
mov x2, #64
bl _read
cmp x0, #0
b.le 4f
mov x2, x0
mov x1, x24
mov w0, wzr
mov w3, wzr
1:
ldrb w4, [x1], #1
cmp w4, #48
b.lo 2f
cmp w4, #57
b.hi 2f
mov w5, #10
mul w0, w0, w5
sub w4, w4, #48
add w0, w0, w4
mov w3, #1
subs x2, x2, #1
b.ne 1b
ret
2:
cbnz w3, 3f
subs x2, x2, #1
b.ne 1b
4:
mov w0, wzr
3:
ret

write_u32_newline:
stp x29, x30, [sp, #-16]!
adrp x1, number_buffer@PAGE
add x1, x1, number_buffer@PAGEOFF
add x1, x1, #15
mov w2, #10
strb w2, [x1]
mov w3, #1
mov w4, #10
1:
udiv w5, w0, w4
msub w6, w5, w4, w0
sub x1, x1, #1
add w6, w6, #48
strb w6, [x1]
add w3, w3, #1
mov w0, w5
cbnz w0, 1b
uxtw x2, w3
bl platform_write
ldp x29, x30, [sp], #16
ret

platform_write:
stp x9, x30, [sp, #-16]!
mov x0, #1
bl _write
ldp x9, x30, [sp], #16
ret

op_divzero:
mov w0, #3
bl _exit
brk #0

op_bad:
mov w0, #2
bl _exit
brk #0

op_bad_module:
mov w0, #10
bl _exit
brk #0

op_not_imported:
mov w0, #11
bl _exit
brk #0

op_bad_function:
mov w0, #12
bl _exit
brk #0

op_bad_register:
mov w0, #13
bl _exit
brk #0

op_platform_error:
mov w0, #14
bl _exit
brk #0
