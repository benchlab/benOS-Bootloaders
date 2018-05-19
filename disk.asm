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
; benOS Disk Startup Script 
; ------------------------------------------------------------------

startup_start:
%ifdef ARCH_i386
    %include "startup-i386.asm"
%endif

%ifdef ARCH_x86_64
    %include "startup-x86_64.asm"
%endif
align 512, db 0
startup_end:

%ifdef KERNEL
    kernel_file:
      %defstr KERNEL_STR %[KERNEL]
      incbin KERNEL_STR
    .end:
    align 512, db 0
%else
    align BLOCK_SIZE, db 0
    %ifdef FILESYSTEM
        filesystem:
            %defstr FILESYSTEM_STR %[FILESYSTEM]
            incbin FILESYSTEM_STR
        .end:
        align BLOCK_SIZE, db 0
    %else
        filesystem:
    %endif
%endif
