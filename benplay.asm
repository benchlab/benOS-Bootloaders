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
; benOS Boot Process - Initialize BenPlay
; ------------------------------------------------------------------

%include "benplay.inc"
SECTION .text
USE16

benplay:

; ------------------------------------------------------------------
; benOS Boot Process - Get Video Card
; ------------------------------------------------------------------

.getvidcard:
    mov ax, 0x4F00
    mov di, BPBECardInfo
    int 0x10
    cmp ax, 0x4F
    je .findbenmode
    mov eax, 1
    ret

; ------------------------------------------------------------------
; benOS Boot Process - Reset Configuration List
; ------------------------------------------------------------------

 .resetlist:
    xor cx, cx
    mov [.minx], cx
    mov [.miny], cx
    mov [benconfig.xres], cx
    mov [benconfig.yres], cx

; ------------------------------------------------------------------
; benOS Boot Process - Find benOS Modes
; ------------------------------------------------------------------

.findbenmode:
    mov si, [BPBECardInfo.videomodeptr]
    mov ax, [BPBECardInfo.videomodeptr+2]
    mov fs, ax
    sub si, 2

; ------------------------------------------------------------------
; benOS Boot Process - Locate benOS Modes
; ------------------------------------------------------------------

.seekbenmodes:
    add si, 2
    mov cx, [fs:si]
    cmp cx, 0xFFFF
    jne .getbenmode
    cmp word [.bengoodmode], 0
    je .resetlist
    jmp .findbenmode

; ------------------------------------------------------------------
; benOS Boot Process - Get benOS Modes
; ------------------------------------------------------------------

.getbenmode:
    push esi
    mov [.benmode], cx
    mov ax, 0x4F01
    mov di, BPBEModeInfo
    int 0x10
    pop esi
    cmp ax, 0x4F
    je .locatedbenmode
    mov eax, 1
    ret

; ------------------------------------------------------------------
; benOS Boot Process - Located benOS Mode
; ------------------------------------------------------------------

.locatedbenmode:
    ;check minimum values, really not minimums from an OS perspective but ugly for users
    cmp byte [BPBEModeInfo.bitsperpixel], 32
    jb .seekbenmodes

; ------------------------------------------------------------------
; benOS Boot Process - Test X Resolution -- Credit: Canonical (MIT)
; ------------------------------------------------------------------

.testx:
    mov cx, [BPBEModeInfo.xresolution]
    cmp word [benconfig.xres], 0
    je .notrequiredx
    cmp cx, [benconfig.xres]
    je .testy
    jmp .seekbenmodes

; ------------------------------------------------------------------
; benOS Boot Process - Test X Resolution Not Required 
; ------------------------------------------------------------------

.notrequiredx:
    cmp cx, [.minx]
    jb .seekbenmodes


; ------------------------------------------------------------------
; benOS Boot Process - benOS Testy Bootloader Video Testing Suite
; ------------------------------------------------------------------

.testy:
    mov cx, [BPBEModeInfo.yresolution]
    cmp word [benconfig.yres], 0
    je .notrequiredy
    cmp cx, [benconfig.yres]
    jne .seekbenmodes    ;as if there weren't enough warnings, USE WITH CAUTION
    cmp word [benconfig.xres], 0
    jnz .setbenmode
    jmp .benboot_test

; ------------------------------------------------------------------------
; benOS Boot Process - benOS Testy Bootloader Video Testing Not Required
; ------------------------------------------------------------------------


.notrequiredy:
    cmp cx, [.miny]
    jb .seekbenmodes


; ------------------------------------------------------------------
; benOS Boot Process - benOS BenBoot Test w/ BenPlay Mode
; ------------------------------------------------------------------

.benboot_test:
    mov al, 13
    call print_char
    mov cx, [.benmode]
    mov [.bengoodmode], cx
    push esi
    mov cx, [BPBEModeInfo.xresolution]
    call print_dec
    mov al, 'x'
    call print_char
    mov cx, [BPBEModeInfo.yresolution]
    call print_dec
    mov al, '@'
    call print_char
    xor ch, ch
    mov cl, [BPBEModeInfo.bitsperpixel]
    call print_dec
    mov si, .modeok
    call print
    xor ax, ax
    int 0x16
    pop esi
    cmp al, 'y'
    je .setbenmode
    cmp al, 's'
    je .savebenmode
    jmp .seekbenmodes

; ------------------------------------------------------------------
; benOS Boot Process - benOS Save BenPlay Video Mode
; ------------------------------------------------------------------

.savebenmode:
    mov cx, [BPBEModeInfo.xresolution]
    mov [config.xres], cx
    mov cx, [BPBEModeInfo.yresolution]
    mov [config.yres], cx
    call save_config

; ------------------------------------------------------------------
; benOS Boot Process - benOS Set BenPlay Video Mode
; ------------------------------------------------------------------

.setbenmode:
    mov bx, [.benmode]
    cmp bx, 0
    je .nobenmode
    or bx, 0x4000
    mov ax, 0x4F02
    int 0x10

; ---------------------------------------------------------------------
; benOS Boot Process - When No benOS BenPlay Mode Is Chosen Or Found
; ---------------------------------------------------------------------


.nobenmode:
    cmp ax, 0x4F
    je .returnbengood
    mov eax, 1
    ret


; ---------------------------------------------------------------------
; benOS Boot Process - Return BenGood Mode
; ---------------------------------------------------------------------


.returnbengood:
    xor eax, eax
    ret

.minx dw 640
.miny dw 480

.modeok db ": Is this OK? (s)ave/(y)es/(n)o    ",8,8,8,8,0

.bengoodmode dw 0
.benmode dw 0

; ---------------------------------------------------------------------
; benOS Boot Process - Print Dec
; ---------------------------------------------------------------------

print_dec:
    mov si, .number


; ---------------------------------------------------------------------
; benOS Boot Process - Clear Dec
; ---------------------------------------------------------------------


.clear:
    mov al, "0"
    mov [si], al
    inc si
    cmp si, .numberend
    jb .clear
    dec si
    call convert_dec
    mov si, .number


.lp:
    lodsb
    cmp si, .numberend
    jae .end
    cmp al, "0"
    jbe .lp


.end:
    dec si
    call print
    ret

.number times 7 db 0
.numberend db 0

convert_dec:
    dec si
    mov bx, si   
    
.cnvrt:
    mov si, bx
    sub si, 4

.ten4:    inc si
    cmp cx, 10000
    jb .ten3
    sub cx, 10000
    inc byte [si]
    jmp .cnvrt

.ten3:    inc si
    cmp cx, 1000
    jb .ten2
    sub cx, 1000
    inc byte [si]
    jmp .cnvrt

.ten2:    inc si
    cmp cx, 100
    jb .ten1
    sub cx, 100
    inc byte [si]
    jmp .cnvrt

.ten1:    inc si
    cmp cx, 10
    jb .ten0
    sub cx, 10
    inc byte [si]
    jmp .cnvrt

.ten0:    inc si
    cmp cx, 1
    jb .return
    sub cx, 1
    inc byte [si]
    jmp .cnvrt

.return:
    ret
