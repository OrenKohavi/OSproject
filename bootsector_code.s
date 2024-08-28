.code16 #16-bit real mode

.globl _start
.org=0x7c00

_start:
    mov $0x7C00, %sp #Setup the stack (We have until 0x500 overwritable)
    mov $msg_welcome, %ax
    call bios_print_string #Print 'Hello, World!'
    #call delay
    mov $msg_loading_os, %ax
    call bios_print_string
    hlt

# **BIOS PRINT STRING**
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
# preserves all registers
delay:
    push %ax
    push %bx
    push %cx
    mov $0xFFFF, %ax
_delay_level1_loop:
    mov $0xFFFF, %bx
    dec %ax
_delay_level2_loop:
    mov $0xFFFF, %cx
_delay_level3_loop:
    dec %cx
    jnz _delay_level3_loop #End loop 3
    dec %bx
    jnz _delay_level2_loop #End loop 2
    dec %ax
    jnz _delay_level1_loop #End loop 1
    #If we get here we are done delaying
    pop %cx
    pop %bx
    pop %ax
    ret

msg_welcome:
    .asciz "Bootloader Loaded - Hello, World!\r\n"
msg_loading_os:
    .asciz "Attempting to load OS into memory..."
