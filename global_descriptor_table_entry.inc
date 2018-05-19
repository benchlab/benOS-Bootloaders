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
; benOS Boot Process - Load Global Descriptor Table TRUC
; ------------------------------------------------------------------

struc GDTEntry
    .limitl resw 1
    .basel resw 1
    .basem resb 1
    .attribute resb 1
    .flags__limith resb 1
    .baseh resb 1
endstruc
