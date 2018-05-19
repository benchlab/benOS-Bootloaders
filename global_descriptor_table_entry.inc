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
