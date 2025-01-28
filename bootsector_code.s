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
    mov $msg_protected_mode, %ax
    call bios_print_string
    mov $0x400, %ax
    call delay
    call setup_protected_mode
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

# **SETUP PROTECTED MODE**
# Switches the processor into protected mode from real mode, then long jumps to 0x8000
# Does not preserve any registers
setup_protected_mode:
    cli #Disable interupts

    #Enable the A20 line
    in $0x92, %al
    or $2, %al
    out %al, $0x92

    #Set segments and load the gdt

    lgdt gdt_descriptor     # Load GDT descriptor

    mov $msg_switching_now, %ax;
    call bios_print_string

    # Switch to protected mode
    mov %cr0, %eax
    or $1, %al
    mov %eax, %cr0

    #long jmp to 0x8000 where the second-stage bootloader is
    ljmp $0x08, $0x8000

msg_welcome:
    .asciz "Bootloader Loaded - Hello, World!\r\n"
msg_loading_secondstage:
    .asciz "Attempting to load second-stage bootloader into memory... "
msg_protected_mode:
    .asciz "Attempting to switch system into protected (32-bit) mode... "
msg_done:
    .asciz "[DONE]\r\n"
msg_switching_now:
    .asciz ">>> SWITCHING NOW!\r\n"
gdt:
    .quad 0x0000000000000000 #zero-th entry in the GDT (must be null)
    #Setup the first entry in the GDT, for code segment
    .word 0xFFFF #bytes 0/1 are the lower part of the limit (so should be max-ed)
    .word 0x0000 #bytes 2/3 are the lower part of the base address (so should be zero)
    .byte 0x00   #byte 4 is also lower part of the base address
    .byte 0x9B   #byte 5 is access byte, so 0b10011011 to show that it is executable with ring 0
    .byte 0xCF   #byte 6 is flags and the upper part of the limit. 0xF for limit, 0b1100=0xC for a page-granularity 32-bit segment
    .byte 0x00   #byte 7 is the upper part of the base address, so should be zero
    #Second entry in the GDT can basically be the same, except for data (so the access byte is different)
    .word 0xFFFF
    .word 0x0000
    .byte 0x00
    .byte 0x93   #0b1001 0011 (Grows upward, data segment, ring 0, read/write enabled)
    .byte 0xCF
    .byte 0x00
gdt_descriptor:
    .word gdt_descriptor - gdt - 1    # Size of GDT
    .long gdt                         # Address of GDT
