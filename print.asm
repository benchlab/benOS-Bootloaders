; ------------------------------------------------------------------
; benOS Initial 
; ------------------------------------------------------------------

; ==================================================================
; benOS Bootloader - Print Stage
; Copyright (C) 2018 Bench Computer, Inc. -- see ~/LICENSE
;
; Based on a free boot loader by E Dehling and the boot loading functions
; found in Rust's Redox. Pieces from Ubuntu's boot loading functions
; were also used in the benOS bootloader's library of parts as well as many
; other bootloaders created over the years.
;
; CREDIT: Canonical in Ubuntu 16.04. Translated to RUST for benOS
; ==================================================================

SECTION .text
USE16

print_line:
    mov al, 13
    call print_char
    mov al, 10
    jmp print_char

print:
    pushf
    cld
.loop:
    lodsb
    test al, al
    jz .done
    call print_char
    jmp .loop
.done:
    popf
    ret

print_char:
    pusha
    mov bx, 7
    mov ah, 0x0e
    int 0x10
    popa
    ret
    
print_hex:
    mov cx, 4

.lp:
    mov al, bh
    shr al, 4

    cmp al, 0xA
    jb .below_0xA

    add al, 'A' - 0xA - '0'

.below_0xA:
    add al, '0'

    call print_char

    shl bx, 4
    loop .lp

    ret
