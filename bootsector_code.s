.code16 #16-bit real mode

.globl _start
.org=0x7c00

_start:
    mov $0x7C00, %sp #Setup the stack (We have until 0x500 overwritable)
    mov $msg_welcome, %ax
    call bios_print_string
    mov $msg_loading_secondstage, %ax
    call bios_print_string
    mov $0x400, %ax
    call delay
    call load_secondstage
    mov $msg_done, %ax
    call bios_print_string
    mov $msg_longmode, %ax
    call bios_print_string
    mov $0x400, %ax
    call delay
    call setup_longmode
    mov $msg_done, %ax
    call bios_print_string
    hlt

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

# **LOAD SECONDSTAGE**
# Loads the second stage bootloader into memory, assumed to occupy the second/third/fourth/fifth sectors (first sector is boot sector)
# Preserves all registers
load_secondstage:
    pusha #easy to save all registers
    mov $0x0204, %ax #ah=02 for selecting the BIOS read sectors function, al=04 to read 4 sectors.
    mov $0x0002, %cx #ch=0 (cylinder number 0), cl=2 (sector number 2, they are one-indexed)
    mov $0x0080, %dx #dh=0 (head number 0), dl=0x80 to select the first hard drive
    ### BIOS Syscall loads into ES:BX (so ES * 16 + BX) - Let's load to 0x8000, so set %es to 0x800
    mov $0x800, %bx
    mov %bx, %es
    mov $0, %bx
    int    $0x13 #trigger BIOS interrupt
    # TODO: Error handling
    popa #easy restore all registers
    ret

# **SETUP LONGMODE**
# Switches the processor into long mode from real mode, then jumps to the address in TODO
# Does not preserve any registers
setup_longmode:
    ret

msg_welcome:
    .asciz "Bootloader Loaded - Hello, World!\r\n"
msg_loading_secondstage:
    .asciz "Attempting to load second-stage bootloader into memory... "
msg_longmode:
    .asciz "Attempting to switch system into long (32-bit) mode... "
msg_done:
    .asciz "[DONE]\r\n"
