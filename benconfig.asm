; ==================================================================
; benOS Bootloader
; Copyright (C) 2018 Bench Computer, Inc. -- see ~/LICENSE
;
; Based on a free boot loader by E Dehling and the boot loading functions
; found in Rust's Redox. Pieces from Ubuntu's boot loading functions
; were also used in the benOS bootloader's library of parts as well as many
; other bootloaders created over the years.
; ==================================================================

; ------------------------------------------------------------------
; benOS Boot Process - Configuration Stage 
; ------------------------------------------------------------------

SECTION .text
USE16

align 512, db 0

; ------------------------------------------------------------------
; benOS Boot Process - BenConfig Initializer
; ------------------------------------------------------------------

benconfig:
  .xres: dw 0
  .yres: dw 0

times 512 - ($ - benconfig) db 0

; ------------------------------------------------------------------
; benOS Boot Process - Save BenConfig
; ------------------------------------------------------------------

save_benconfig:
    mov eax, (benconfig - boot) / 512
    mov bx, benconfig
    mov cx, 1
    xor dx, dx
    call store
    ret
