.code16 #16-bit real mode

.globl _start
.org=0x7c00

_start:
    mov $0x7C00, %sp #Setup the stack (We have until 0x500 overwritable)
    mov $msg_welcome, %ax
    call bios_print_string #Print 'Hello, World!''
    mov $0x400, %ax
    call delay
    mov $msg_loading_os, %ax
    call bios_print_string
    call load_os
    mov $msg_finished_loading_os, %ax
    call bios_print_string

# **BIOS PRINT STRING**
# Takes a string pointer in %ax to print using BIOS syscalls
# Preserves all registers except %ax
bios_print_string:
    push %bx
    push %si
    #First argument is in %ax, so move that somewhere else because %al is needed for the BIOS syscall
    mov %ax, %si #si is the pointer to the string now
    #Setup BIOS text syscall
    mov $0x0E, %ah
    mov $0x0007, %bx
_bios_print_string_loop:
    mov (%si), %al #Deref character
    inc %si #Increment string pointer
    cmp $0, %al #If null terminator reached return
    je _bios_print_string_exit
    int $0x10 #Else null terminator not reached (do BIOS syscall)
    jmp _bios_print_string_loop #loop again to print the next char
_bios_print_string_exit:
    pop %si
    pop %bx
    ret

# **DELAY**
# Takes a number in %ax determining how long to delay
# preserves all registers except ax
delay:
    xchg %ax, %dx
    push %bx
    push %cx
    push %dx
    mov %dx, %ax
    mov %dx, %bx
    mov %dx, %cx
_delay_loop:
    dec %cx
    jnz _delay_loop #End inntermost loop
    mov %dx, %cx
    dec %bx
    jnz _delay_loop #End middle loop
    mov %dx, %bx
    dec %ax
    jnz _delay_loop #End outermost loop
    #If we get here we are done delaying, ax is zero
    pop %dx
    pop %cx
    pop %bx
    ret

msg_welcome:
    .asciz "Bootloader Loaded - Hello, World!\r\n"
msg_loading_os:
    .asciz "Attempting to load OS into memory... "
msg_done:
    .asciz "[DONE]\r\n"
