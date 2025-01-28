.code32
.org=0x8000

#First thing that runs after the CPU enters protected 32-bit mode
#Priority here is to set up a C envirionment by allocating room for .bss and copying .data into memory
protected_mode_entry:
    
