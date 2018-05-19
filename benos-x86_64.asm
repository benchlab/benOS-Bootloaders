; ==================================================================
; benOS Bootloader
; Copyright (C) 2018 Bench Computer, Inc. -- see ~/LICENSE
;
; Based on a free boot loader by E Dehling and the boot loading functions
; found in Rust's Redox. Pieces from Ubuntu's boot loading functions
; were also used in the benOS bootloader's library of parts as well as many
; other bootloaders created over the years.
; ==================================================================

; =================================================================================
; benOS Bootloader - BenBoot Stage
; =================================================================================

; ------------------------------------------------------------------
; benOS BenBoot Stage - Step By Step
; 1. Check Readiness of benOS Bootloader
; 2. Get CPU ID
; 3. Initialize Table
; 4. Start benOS Stack
; 5. Exit benOS Stack
; 6. Exit Code
; ------------------------------------------------------------------

benboot:
    .ready: dq 0
    .cpu_id: dq 0
    .page_table: dq 0
    .stack_start: dq 0
    .stack_end: dq 0
    .code: dq 0

    times 512 - ($ - benboot) db 0

; =================================================================================
; benOS Bootloader - 'startup_ap' - Initialize benOS Stack
; =================================================================================

startup_ap:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

; ==================================================================
; benOS Bootloader - Initialize benOS Stack, FPU and SSE
; ==================================================================

    mov sp, 0x7C00

    call initialize.fpu
    call initialize.sse

; ==================================================================
; benOS Bootloader - CR3 Point to PML4
; ==================================================================

    mov edi, 0x70000
    mov cr3, edi


; =============================================================================
; benOS Bootloader - Enable FXSAVE/FXRSTOR/PG_GLOBAL/PG_ADDR_EXT/PG_SIZE_EXT
; =============================================================================

    mov eax, cr4
    or eax, 1 << 9 | 1 << 7 | 1 << 5 | 1 << 4
    mov cr4, eax

; ======================================================================
; benOS Bootloader - Load Global Descriptor Tables In Protected Mode
; ======================================================================

    lgdt [gdtr]

    mov ecx, 0xC0000080               ; Read via the Extended Feature Enable Register Model Specific Registers.
    rdmsr
    or eax, 1 << 11 | 1 << 8          ; Enable Long-Mode-Enable and NXE bit for the USE64 Variable later.
    wrmsr

; ======================================================================
; benOS Bootloader - Enable Simulataneous Paging and Protection
; ======================================================================

    mov ebx, cr0
    or ebx, 1 << 31 | 1 << 16 | 1     ;Bit 31: benOS Paging, Bit 16: Write-Protected benOS Microkernel, Bit 0: Protected Mode
    mov cr0, ebx

; ================================================================================================
; benOS Bootloader - Enable Long Mode By Far Jumping & Load Microkernel Code Syntax Using 64 Bit
; ================================================================================================

    jmp gdt.kernel_code:long_mode_ap

; ======================================================================
; benOS Bootloader - Import benOS Common Loaders To x86_64 Boot Process 
; ======================================================================

    %include "ben_common.asm"

; ======================================================================
; benOS Bootloader - Initialize benOS Arch
; ======================================================================

startup_benos_arch:
    cli
   
    ; =============================================================================
    ; benOS Bootloader - Setup Page Tables and Identity Mapping on First Gigabyte
    ; ============================================================================

    mov ax, 0x7000
    mov es, ax

    xor edi, edi
    xor eax, eax
    mov ecx, 6 * 4096 / 4 
    cld
    rep stosd

    xor edi, edi
    
    ; =============================================================================
    ; benOS Bootloader - Connect 1st PML4 and 2nd to Last PML4 to PDP
    ; ============================================================================

    mov DWORD [es:edi], 0x71000 | 1 << 1 | 1
    mov DWORD [es:edi + 510*8], 0x71000 | 1 << 1 | 1
    add edi, 0x1000
 
    ; =============================================================================
    ; benOS Bootloader - Connect Last PML4 to PDP
    ; ============================================================================
    
    mov DWORD [es:edi - 8], 0x70000 | 1 << 1 | 1
    
    ; =============================================================================
    ; benOS Bootloader - Connect All Four PDPs to PD 
    ; ============================================================================
    
    mov DWORD [es:edi], 0x72000 | 1 << 1 | 1
    mov DWORD [es:edi + 8], 0x73000 | 1 << 1 | 1
    mov DWORD [es:edi + 16], 0x74000 | 1 << 1 | 1
    mov DWORD [es:edi + 24], 0x75000 | 1 << 1 | 1
    add edi, 0x1000
    
    ; =============================================================================
    ; benOS Bootloader - Connect All PD's (Max 512 per PDP and 2 megabytes each)
    ; ============================================================================
    
    mov ebx, 1 << 7 | 1 << 1 | 1
    mov ecx, 4*512
    
; ======================================================================
; benOS Bootloader - Process Data Stage 
; ======================================================================

.setpd:
    mov [es:edi], ebx
    add ebx, 0x200000
    add edi, 8
    loop .setpd

    xor ax, ax
    mov es, ax

; ======================================================================
; benOS Bootloader - CR3 Pointer To PML4
; ======================================================================

    mov edi, 0x70000
    mov cr3, edi

; =================================================================================
; benOS Bootloader - Enable FXSAVE/FXRSTOR, PG Global, PG Address Ext, PG Size Ext
; =================================================================================

    mov eax, cr4
    or eax, 1 << 9 | 1 << 7 | 1 << 5 | 1 << 4
    mov cr4, eax

; =================================================================================
; benOS Bootloader - Load Protected Mode For Global Descriptor Tables
; =================================================================================

    lgdt [gdtr]

    mov ecx, 0xC0000080               ; Read via the Extended Feature Enable Register Model Specific Registers.
    rdmsr
    or eax, 1 << 11 | 1 << 8          ; Enable Long-Mode-Enable and NXE bit for the USE64 Variable later.
    wrmsr

; =======================================================================================
; benOS Bootloader - Enable Simultaneous Paging / Protection To Use With 64 Bit Hardware
; =======================================================================================

    mov ebx, cr0
    or ebx, 1 << 31 | 1 << 16 | 1     ;Bit 31: benOS Paging, Bit 16: Write-Protect benOS Microkernel, Bit 0: Protected Mode
    mov cr0, ebx

; ====================================================================================================
; benOS Bootloader - Far Jump-Based Enablement Of benOS Long Mode While Loading Code Syntax + 64 Bit
; ====================================================================================================

    jmp gdt.kernel_code:long_mode

; ======================================================================
; benOS Bootloader - Load USE64 Global Bootloader Function
; ======================================================================

USE64

; =================================================================================
; benOS Bootloader - Long Mode Loader + Other 64 Bit Data Segments
; =================================================================================

long_mode:
    mov rax, gdt.kernel_data
    mov ds, rax
    mov es, rax
    mov fs, rax
    mov gs, rax
    mov ss, rax
    
; =================================================================================
; benOS Bootloader - benOS Stack Base 
; =================================================================================

    mov rsi, 0xFFFFFF0000080000
    mov [args.stack_base], rsi

; =================================================================================
; benOS Bootloader - benOS Stack Size 
; =================================================================================

    mov rcx, 0x1F000
    mov [args.stack_size], rcx

; =================================================================================
; benOS Bootloader - benOS Stack Pointer
; =================================================================================

    mov rsp, rsi
    add rsp, rcx

; =================================================================================
; benOS Bootloader - Copy Bootloader Environment Variables To benOS Stack
; =================================================================================

%ifdef KERNEL
    mov rsi, 0
    mov rcx, 0
%else
    mov rsi, benfs.env
    mov rcx, benfs.env.end - benfs.env
%endif
    mov [args.env_size], rcx
    
; =================================================================================
; benOS Bootloader - Copy Environment Variables Function
; =================================================================================

.copy_env:
    cmp rcx, 0
    je .no_env
    dec rcx
    mov al, [rsi + rcx]
    dec rsp
    mov [rsp], al
    jmp .copy_env
    
; =================================================================================
; benOS Bootloader - Function When Environment Variables Are Non-Existent 
; =================================================================================

.no_env:
    mov [args.env_base], rsp

; =================================================================================
; benOS Bootloader - benOS Stack Alignment 
; =================================================================================

    and rsp, 0xFFFFFFFFFFFFFFF0

; =================================================================================
; benOS Bootloader - Set Arguments From Environment Variables and Microkernel
; =================================================================================

    mov rdi, args

; =================================================================================
; benOS Bootloader - benOS Microkernel Entry Point
; =================================================================================

    mov rax, [args.kernel_base]
    call [rax + 0x18]
 
; =================================================================================
; benOS Bootloader - Halt Stage
; =================================================================================

.halt:
    cli
    hlt
    jmp .halt

; =================================================================================
; benOS Bootloader - Long Mode AP
; =================================================================================

long_mode_ap:
    mov rax, gdt.kernel_data
    mov ds, rax
    mov es, rax
    mov fs, rax
    mov gs, rax
    mov ss, rax

    mov rcx, [benboot.stack_end]
    lea rsp, [rcx - 256]

    mov rdi, benboot.cpu_id

    mov rax, [benboot.code]
    mov qword [benboot.ready], 1
    jmp rax

; =================================================================================
; benOS Bootloader - Finalization 
; =================================================================================


gdtr:
    dw gdt.end + 1  ; size
    dq gdt          ; offset

gdt:
.null equ $ - gdt
    dq 0

.kernel_code equ $ - gdt
istruc GDTEntry
    at GDTEntry.limitl, dw 0
    at GDTEntry.basel, dw 0
    at GDTEntry.basem, db 0
    at GDTEntry.attribute, db attrib.present | attrib.user | attrib.code
    at GDTEntry.flags__limith, db flags.long_mode
    at GDTEntry.baseh, db 0
iend

.kernel_data equ $ - gdt
istruc GDTEntry
    at GDTEntry.limitl, dw 0
    at GDTEntry.basel, dw 0
    at GDTEntry.basem, db 0
    at GDTEntry.attribute, db attrib.present | attrib.user | attrib.writable
    at GDTEntry.flags__limith, db 0
    at GDTEntry.baseh, db 0
iend

.end equ $ - gdt
