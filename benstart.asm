; ==================================================================
; benOS Bootloader
; Copyright (C) 2018 Bench Computer, Inc. -- see ~/LICENSE
;
; Based on a free boot loader by E Dehling and the boot loading functions
; found in Rust's Redox. Pieces from Ubuntu's boot loading functions
; were also used in the benOS bootloader's library of parts as well as many
; other bootloaders created over the years.
; ==================================================================


ORG 0x7C00
SECTION .text
USE16

; ------------------------------------------------------------------
; benOS Boot Process - Starting the Engines
; ------------------------------------------------------------------

boot: ; dl comes with disk
    ; benos boot process 
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; start the benOS engines
    mov sp, 0x7C00

    ; start the CS engines
    push ax
    push word .init_codeseg
    retf

; ------------------------------------------------------------------
; benOS Boot Process - Init Code Segments
; ------------------------------------------------------------------

.init_codeseg:
    ; After the boot process, benOS will need to retrieve the number of the primary disk. 
    ; We are able to do that with mov and the [primary-disk].
    ; After retreiving disk number, it's registered using 'dl', an 8 byte registry.
    mov [disk], dl


    mov si, name
    call print
    call print_line

    mov bx, (startup_start - boot) / 512
    call print_hex
    call print_line

    mov bx, startup_start
    call print_hex
    call print_line

    mov eax, (startup_start - boot) / 512
    mov bx, startup_start
    mov cx, (startup_end - startup_start) / 512
    xor dx, dx
    call load

    call print_line
    mov si, finished
    call print
    call print_line

    jmp startup

load:
    cmp cx, 127
    jbe .ben_ready

    pusha
    mov cx, 127
    call load
    popa
    add eax, 127
    add dx, 127 * 512 / 16
    sub cx, 127

    jmp load

.ben_ready:
    mov [BENFIN.addr], eax
    mov [BENFIN.buf], bx
    mov [BENFIN.count], cx
    mov [BENFIN.seg], dx

    call print_benfin

    mov dl, [disk]
    mov si, BENFIN
    mov ah, 0x42
    int 0x13
    jc error
    ret

  store:
      cmp cx, 127
      jbe .ben_ready

      pusha
      mov cx, 127
      call store
      popa
      add ax, 127
      add dx, 127 * 512 / 16
      sub cx, 127

      jmp store

  .ben_ready:
      mov [BENFIN.addr], eax
      mov [BENFIN.buf], bx
      mov [BENFIN.count], cx
      mov [BENFIN.seg], dx

      call print_benfin

      mov dl, [disk]
      mov si, BENFIN
      mov ah, 0x43
      int 0x13
      jc error
      ret ; return ben_ready

print_benfin:
    mov al, 13
    call print_char

    mov bx, [BENFIN.addr + 2]
    call print_hex

    mov bx, [BENFIN.addr]
    call print_hex

    mov al, '#'
    call print_char

    mov bx, [BENFIN.count]
    call print_hex

    mov al, ' '
    call print_char

    mov bx, [BENFIN.seg]
    call print_hex

    mov al, ':'
    call print_char

    mov bx, [BENFIN.buf]
    call print_hex

    ret ; return printed result of BENFIN

error:
    call print_line

    mov bh, 0
    mov bl, ah
    call print_hex

    mov al, ' '
    call print_char

    mov si, errored
    call print
    call print_line
.halt:
    cli
    hlt
    jmp .halt

%include "print.asm"

name: db "benOS Loader - Stage1",0
errored: db "Was unable to read from local primary disk.",0
finished: db "benOS Loader - Stage2",0

disk: db 0 ; disk with databyte 0

; ------------------------------------------------------------------
; benOS Boot Process - BENFIN
; ------------------------------------------------------------------

BENFIN:
        db 0x10
        db 0
.count: dw 0 ; integer 13 resets this to the number of blocks written to/from the primary disk in the boot process.
.buf:   dw 0 ; Sets 0:7c00 as the memory in-buffer destination address
.seg:   dw 0 ; Sets zero as the in-memory page, which we will utilize later in the boot process
.addr:  dq 0 ; put the lba to read in this spot

times 510-($-$$) db 0 ; databyte 0
db 0x55 ; databyte 1
db 0xaa ; databyte 2
