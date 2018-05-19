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
