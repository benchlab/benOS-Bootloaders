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

%define X_BLOCK_SHIFT 12
%define X_BLOCK_SIZE (1 << X_BLOCK_SHIFT)

; ------------------------------------------------------------------
; benOS Initial Extent Structure For Block Data
; ------------------------------------------------------------------

struc Extent
    .block: resq 1,
    .length: resq 1
endstruc

; ------------------------------------------------------------------
; benOS Initial BenUnit Structure
; ------------------------------------------------------------------

struc BenUnit
    .mode: resw 1
    .uid: resd 1
    .gid: resd 1
    .ctime: resq 1
    .ctime_nsec: resd 1
    .mtime: resq 1
    .mtime_nsec: resd 1
    .name: resb 222
    .parent: resq 1
    .next: resq 1
    .extents: resb (X_BLOCK_SIZE - 272)
endstruc

; ------------------------------------------------------------------
; benOS Initial BenHeader Structure For Data Block Header
; ------------------------------------------------------------------

struc BenHeader
    ; benFS Signature
    ; This should be b"benFS\0". If not, there are major bootloader errors. << IMPORTANT
    .ben_signature: resb 8
    ; benFS BenHeader Version
    .ben_version: resq 1,
    ; BenchDisk ID, a 128-bit BenchX on-board disk UID
    .benx_uuid: resb 16,
    ; BenchDisk size 
    .size: resq 1,
    ; Block of root benOS benunit within the stack
    .root: resq 1,
    ; Block of free space benOS benunit
    .free: resq 1
    ; benFS BenHeader Padding
    .padding: resb (X_BLOCK_SIZE - 56)
endstruc

; ------------------------------------------------------------------
; benOS Load benFS along with initial BenHeader
; ------------------------------------------------------------------

benfs:
        call benfs.open
        test eax, eax
        jz .ben_header
        ret

; ------------------------------------------------------------------
; benOS Load Full BenHeader
; ------------------------------------------------------------------

    .ben_header:
        mov eax, [.ben_header + BenHeader.root]
        mov bx, .ben_dir
        call .benunit

        jmp benfs.root

; ------------------------------------------------------------------
; benOS Load BenUnit (Load Disk and benOS FileSystem)
; ------------------------------------------------------------------

    .benunit:
        shl eax, (X_BLOCK_SHIFT - 9)
        add eax, (benos_filesystem - boot)/512
        mov cx, (X_BLOCK_SIZE/512)
        mov dx, 0
        call load
        call print_line
        ret

        align X_BLOCK_SIZE, db 0

; ------------------------------------------------------------------
; benOS Load BenHeader
; ------------------------------------------------------------------

    .ben_header:
        times X_BLOCK_SIZE db 0

; ------------------------------------------------------------------
; benOS Load BenDir
; ------------------------------------------------------------------

    .ben_dir:
        times X_BLOCK_SIZE db 0

; ------------------------------------------------------------------
; benOS Load BenFile
; ------------------------------------------------------------------

    .ben_file:
        times X_BLOCK_SIZE db 0

    .ben_env:
        db "BENOSFS_BENX_UUID="
    .ben_env.uuid:
        db "00000000-0000-0000-0000-000000000000"
    .ben_env.end:
        db 0

; ------------------------------------------------------------------
; benOS Open benFS Local File System
; ------------------------------------------------------------------

benfs.open:
        mov eax, 0
        mov bx, benfs.ben_header
        call benfs.benunit

        mov bx, 0

; ------------------------------------------------------------------
; benOS Load benFS Signature
; ------------------------------------------------------------------

    .ben_sig:
        mov al, [benfs.ben_header + BenHeader.ben_signature + bx]
        mov ah, [.ben_signature + bx]
        cmp al, ah
        jne .ben_sig_err
        inc bx
        cmp bx, 8
        jl .ben_sig

        mov bx, 0

; ------------------------------------------------------------------
; benOS Load benFS Version
; ------------------------------------------------------------------

    .ben_ver:
        mov al, [benfs.ben_header + BenHeader.ben_version + bx]
        mov ah, [.ben_version + bx]
        cmp al, ah
        jne .ben_ver_err
        inc bx
        jl .ben_ver

        lea si, [benfs.ben_header + BenHeader.signature]
        call print
        mov al, ' '
        call print_char

        mov di, benfs.ben_env.benx_uuid
        xor si, si

; ------------------------------------------------------------------
; benOS Load benFS (benX) UUID
; ------------------------------------------------------------------

    .benx_uuid:
        cmp si, 4
        je .benx_uuid.dash
        cmp si, 6
        je .benx_uuid.dash
        cmp si, 8
        je .benx_uuid.dash
        cmp si, 10
        je .benx_uuid.dash
        jmp .benx_uuid.no_dash

; ------------------------------------------------------------------
; benOS Load benFS (benX) UUID DASH, NODASH, CHAR and all below 0xA
; ------------------------------------------------------------------

    .benx_uuid.dash:
        mov al, '-'
        mov [di], al
        inc di
    .benx_uuid.no_dash:
        mov bx, [benfs.ben_header + BenHeader.benx_uuid + si]
        rol bx, 8

        mov cx, 4
    .benx_uuid.char:
        mov al, bh
        shr al, 4

        cmp al, 0xA
        jb .benx_uuid.below_0xA

        add al, 'a' - 0xA - '0'
    .benx_uuid.below_0xA:
        add al, '0'

        mov [di], al
        inc di

        shl bx, 4
        loop .benx_uuid.char

        add si, 2
        cmp si, 16
        jb .benx_uuid

        mov si, benfs.ben_env.benx_uuid
        call print
        call print_line

        xor ax, ax
        ret

; ------------------------------------------------------------------
; benOS Load benFS Bootloader Error Messages
; ------------------------------------------------------------------

    .ben_err_msg: db "benOS bootloader failed to open benFS: ",0
    .ben_sig_err_msg: db "benFS Signature error",13,10,0
    .ben_ver_err_msg: db "benFS Version error",13,10,0

; ------------------------------------------------------------------
; benOS Load benFS Signature Error
; ------------------------------------------------------------------

    .ben_sig_err:
        mov si, .ben_err_msg
        call print

        mov si, .ben_sig_err_msg
        call print

        mov ax, 1
        ret

; ------------------------------------------------------------------
; benOS Load benFS Version Error
; ------------------------------------------------------------------

    .ben_ver_err:
        mov si, .ben_err_msg
        call print

        mov si, .ben_ver_err_msg
        call print

        mov ax, 1
        ret

; ------------------------------------------------------------------
; benOS Load benFS Signature
; ------------------------------------------------------------------

    .ben_signature: db "benFS",0

; ------------------------------------------------------------------
; benOS Load benFS Version
; ------------------------------------------------------------------

    .ben_version: dq 3


; ------------------------------------------------------------------
; benOS Load benFS Root Local FileSystem
; ------------------------------------------------------------------

benfs.root:
        lea si, [benfs.ben_dir + BenUnit.name]
        call print
        call print_line

; ------------------------------------------------------------------
; benOS Load benFS Root Local FileSystem [LOOP]
; ------------------------------------------------------------------

    .lp:
        mov bx, 0

; ------------------------------------------------------------------
; benOS Load benFS Root Local FileSystem [EXTENTS]
; ------------------------------------------------------------------

    .ext:
        mov eax, [benfs.ben_dir + BenUnit.extents + bx + Extent.block]
        test eax, eax
        jz .next

        mov ecx, [benfs.ben_dir + BenUnit.extents + bx + Extent.length]
        test ecx, ecx
        jz .next

        add ecx, X_BLOCK_SIZE
        dec ecx
        shr ecx, X_BLOCK_SHIFT

        push bx

    .ext_sec:
        push eax
        push ecx

        mov bx, benfs.file
        call benfs.benunit

        mov bx, 0
    .ext_sec_kernel:
        mov al, [benfs.file + BenUnit.name + bx]
        mov ah, [.kernel_name + bx]

        cmp al, ah
        jne .ext_sec_kernel_break

        inc bx

        test ah, ah
        jnz .ext_sec_kernel

        pop ecx
        pop eax
        pop bx
        jmp benfs.kernel

    .ext_sec_kernel_break:
        pop ecx
        pop eax

        inc eax
        dec ecx
        jnz .ext_sec

        pop bx

        add bx, Extent_size
        cmp bx, (X_BLOCK_SIZE - 272)
        jb .ext

; ------------------------------------------------------------------
; benOS Load benFS Next BenUnit
; ------------------------------------------------------------------

    .next:
        mov eax, [benfs.ben_dir + BenUnit.next]
        test eax, eax
        jz .no_kernel

        mov bx, benfs.ben_dir
        call benfs.benunit
        jmp .lp

; ------------------------------------------------------------------
; benOS Load benFS - [IF NO KERNEL]
; ------------------------------------------------------------------

    .no_kernel:
        mov si, .no_kernel_msg
        call print

        mov si, .kernel_name
        call print

        call print_line

        mov eax, 1
        ret


; ------------------------------------------------------------------
; benOS Load benFS - Microkernel Information / No Kernel Error Message
; ------------------------------------------------------------------

    .kernel_name: db "kernel",0
    .no_kernel_msg: db "benOS bootloader: Did not find ",0

; ------------------------------------------------------------------
; benOS Load benFS - Load Microkernel
; ------------------------------------------------------------------

benfs.kernel:
        lea si, [benfs.ben_file + BenUnit.name]
        call print
        call print_line

        mov edi, [args.kernel_base]

; ------------------------------------------------------------------
; benOS Load benFS - Microkernel Loader [LOOP]
; ------------------------------------------------------------------

    .lp:
        mov bx, 0

; ------------------------------------------------------------------
; benOS Load benFS - Microkernel Loader [EXTENTS]
; ------------------------------------------------------------------

    .ext:
        mov eax, [benfs.ben_file + BenUnit.extents + bx + Extent.block]
        test eax, eax
        jz .next

        mov ecx, [benfs.ben_file + BenUnit.extents + bx + Extent.length]
        test ecx, ecx
        jz .next

        push bx

        push eax
        push ecx
        push edi


        shl eax, (X_BLOCK_SHIFT - 9)
        add eax, (benos_filesystem - boot)/512
        add ecx, X_BLOCK_SIZE
        dec ecx
        shr ecx, 9
        call load_extent

        pop edi
        pop ecx
        pop eax

        add edi, ecx

        pop bx

        add bx, Extent_size
        cmp bx, Extent_size * 16
        jb .ext

; ------------------------------------------------------------------
; benOS Load benFS - Load Next BenUnit
; ------------------------------------------------------------------

    .next:
        mov eax, [benfs.ben_file + BenUnit.next]
        test eax, eax
        jz .done

        push edi

        mov bx, benfs.ben_file
        call benfs.benunit

        pop edi
        jmp .lp

; ------------------------------------------------------------------
; benOS Load benFS - Finalizing Loading of benFS Local File System
; ------------------------------------------------------------------

    .done:
        sub edi, [args.kernel_base]
        mov [args.kernel_size], edi

        xor eax, eax
        ret
