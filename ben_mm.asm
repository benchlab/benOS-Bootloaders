; ==================================================================
; benOS Bootloader
; Copyright (C) 2018 Bench Computer, Inc. -- see ~/LICENSE
;
; The official bootloader for benOS and BenchX desktop/laptop products.
; The first bootloader built for a decentralized operating system.
; Many bootloaders were looked at and utilized in the creation of 
; benOS's BenchX bootloader.
; 
; Bootloaders we utilized: Ubuntu, MikeOS, Debian, Linux Mint, ReOS
; ==================================================================

; ------------------------------------------------------------------
; benOS Bootloader - Memory Mapping
; ------------------------------------------------------------------

SECTION .text
USE16

; ------------------------------------------------------------------
; benOS Bootloader - At 0x500 to 0x5000 We Generate A Memory Map
; /// BenchX Desktop will pull from available memory that hasn't been used.
; /// At this boot stage the benOS microkernel and bootloader are already utilizing 
; memory from your BenchX Desktop, to startup benOS. 
; ------------------------------------------------------------------

ben_mm:
.start  equ 0x0500
.end    equ 0x5000
.length equ .end - .start

    xor eax, eax
    mov di, .start
    mov ecx, .length / 4 ; moving 4 Bytes at once
    cld
    rep stosd

    mov di, .start
    mov edx, 0x534D4150 ;  Set EDX to the magic number 0x534D4150. 
    xor ebx, ebx

; ------------------------------------------------------------------
; benOS Bootloader - Memory Mapping Loop
; ------------------------------------------------------------------

.lp:
    mov eax, 0xE820
    mov ecx, 24

    int 0x15
    jc .done ; MM Loop either errors out or finishes.

    cmp ebx, 0
    je .done ; MM Loop finalizes its boot stage loop process.

    add di, 24
    cmp di, .end
    jb .lp ; MM Loop has buffer space available and left over.

; ----------------------------------------------------------------------
; benOS Bootloader - Memory Mapping Complete, Returns Map > Next Stage
; ----------------------------------------------------------------------

.done:
    ret
