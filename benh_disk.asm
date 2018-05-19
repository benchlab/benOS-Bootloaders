; ==================================================================
; benOS Bootloader - Disk Stage
; Copyright (C) 2018 Bench Computer, Inc. -- see ~/LICENSE
;
; Based on a free boot loader by E Dehling and the boot loading functions
; found in Rust's Redox. Pieces from Ubuntu's boot loading functions
; were also used in the benOS bootloader's library of parts. 
; ==================================================================

sectalign off

%include "benstart.asm"

; ------------------------------------------------------------------
; benOS Launch Start >> i386 or x86_64
; ------------------------------------------------------------------

benos_launch_start:

; ------------------------------------------------------------------
; benOS i386 Launch Loader
; ------------------------------------------------------------------

%ifdef ARCH_i386
    %include "benos-i386.asm"
%endif

; ------------------------------------------------------------------
; benOS x86_64 Launch Loader
; ------------------------------------------------------------------

%ifdef ARCH_x86_64
    %include "benos-x86_64.asm"
%endif
align 512, db 0
benos_launch_end:

; ------------------------------------------------------------------
; benOS Microkernel Loader
; ------------------------------------------------------------------

%ifdef KERNEL
    benos_kernel_file:
      %defstr KERNEL_STR %[KERNEL]
      incbin KERNEL_STR
    .end:
    align 512, db 0
%else

; ------------------------------------------------------------------
; benOS If Microkernel Has Already Loaded, Load FileSystem
; ------------------------------------------------------------------

    align BLOCK_SIZE, db 0
    %ifdef BEN_FILESYSTEM
        benos_filesystem:
            %defstr BEN_FILESYSTEM_STR %[BEN_FILESYSTEM]
            incbin BEN_FILESYSTEM_STR
        .end:
        align BLOCK_SIZE, db 0

; --------------------------------------------------------------------------------
; benOS If Microkernel and FileSystem Already Loaded, Execute Loaded Filesystem
; --------------------------------------------------------------------------------

    %else
        benos_filesystem:
    %endif
%endif
