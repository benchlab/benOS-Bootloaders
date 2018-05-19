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

SECTION .text
USE16

; ------------------------------------------------------------------
; benOS Bootloader - Switches to BENUR Mode
; ------------------------------------------------------------------

benur:
    cli

    lgdt [benur_gdtr]

    push es
    push ds

    mov  eax, cr0          ; switch to pmode by
    or al,1                ; set pmode bit
    mov  cr0, eax

    jmp $+2


; ------------------------------------------------------------------
; benOS Bootloader - When the BENUR register is handed a selector
; a "SDCR" (Segment Descriptor Cache Register) is completed with 
; wht we call descriptor values/data that includes the size of the 
; value/data itself. When switching back to BENR (BenReal Mode), these
; values cannot and are not mutable or modified at this boot stage. 
; Even with the 16-bit register active in this loader stage, it is still
; unable to be modified. At this point, the 64K limitation is invalid
; and 32-bit offsets can and are utilized with BENUR addressing rules.
; ------------------------------------------------------------------

    mov bx, benur_gdt.data
    mov es, bx
    mov ds, bx

    and al,0xFE            ; back to BENUR by
    mov  cr0, eax          ; toggling bit again

    pop ds
    pop es
    sti
    ret

; ------------------------------------------------------------------
; benOS Bootloader - Load BENUR Global Descriptor Tables 
; ------------------------------------------------------------------
benur_gdtr:
    dw benur_gdt.end + 1  ; size
    dd benur_gdt          ; offset

; ------------------------------------------------------------------
; benOS Bootloader - Load BENUR Global Descriptor Tables 
; ------------------------------------------------------------------

benur_gdt:
.null equ $ - benur_gdt
    dq 0
.data equ $ - benur_gdt
    istruc GDTEntry
        at GDTEntry.limitl,        dw 0xFFFF
        at GDTEntry.basel,         dw 0x0
        at GDTEntry.basem,         db 0x0
        at GDTEntry.attribute,        db attrib.present | attrib.user | attrib.writable
        at GDTEntry.flags__limith, db 0xFF | flags.granularity | flags.default_operand_size
        at GDTEntry.baseh,         db 0x0
    iend
.end equ $ - benur_gdt
