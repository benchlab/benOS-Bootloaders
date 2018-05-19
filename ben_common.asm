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
; benOS Common Loaders - Load Kernel Args
; ------------------------------------------------------------------

SECTION .text
USE16

args:
    .kernel_base dq 0x100000
    .kernel_size dq 0
    .stack_base dq 0
    .stack_size dq 0
    .env_base dq 0
    .env_size dq 0

; ------------------------------------------------------------------
; benOS Common Loaders - Load Kernel Args
; ------------------------------------------------------------------

startup:
    ; enable A20-Line via IO-Port 92, might not work on all motherboards
    in al, 0x92
    or al, 2
    out 0x92, al

    %ifdef KERNEL
        mov edi, [args.kernel_base]
        mov ecx, (benos_kernel_file.end - benos_kernel_file)
        mov [args.kernel_size], ecx

        mov eax, (benos_kernel_file - boot)/512
        add ecx, 511
        shr ecx, 9
        call load_extent
    %else
        call benfs
        test eax, eax
        jnz error
    %endif

    jmp .loaded_benos_kernel

.loaded_benos_kernel:

; ------------------------------------------------------------------
; benOS Common Loaders - benOS Memory Mapping Call
; ------------------------------------------------------------------

    call ben_mm

; ------------------------------------------------------------------
; benOS Common Loaders - benOS BenPlay Video Loaders / Mode Finder
; ------------------------------------------------------------------

    call benplay

; ------------------------------------------------------------------
; benOS Common Loaders - Initialize FPU
; ------------------------------------------------------------------

    mov si, init_fpu_msg
    call print
    call initialize.fpu

; ------------------------------------------------------------------
; benOS Common Loaders - Initialize SSE 
; ------------------------------------------------------------------

    mov si, init_sse_msg
    call print
    call initialize.sse

    mov si, startup_ben_arch_msg
    call print

    jmp startup_ben_arch


; ------------------------------------------------------------------
; benOS Common Loaders 
; LOAD DISK 'EXTENT' INTO HIGH MEMORY
; EAX - Sector Address
; ECX - Sector Count
; EDI - Destination
; ------------------------------------------------------------------

load_extent:

; ------------------------------------------------------------------
; benOS Common Loaders 
; LOADING KERNEL TO 1 MEGABYTE
; MOVE PARTIAL PIECE OF BENOS MICROKERNEL TO BENOS_LAUNCH_END
; THEN - COPY IT UP
; THEN - REPEAT UNTIL ALL OF THE benOS MICROKERNEL HAS BEEN LOADED
; ------------------------------------------------------------------

    buffer_size_sectors equ 127

.lp:
    cmp ecx, buffer_size_sectors
    jb .break

; ------------------------------------------------------------------
; benOS Common Loaders - Save Counter
; ------------------------------------------------------------------

    push eax
    push ecx

    push edi

; ------------------------------------------------------------------
; benOS Common Loaders - Populate Buffer
; ------------------------------------------------------------------

    mov ecx, buffer_size_sectors
    mov bx, benos_launch_end
    mov dx, 0x0

; ------------------------------------------------------------------
; benOS Common Loaders - Load Sector
; ------------------------------------------------------------------

    call load


; ------------------------------------------------------------------
; benOS Common Loaders - Setup benUnreal Mode
; ------------------------------------------------------------------

    call ben_unreal

    pop edi


; ------------------------------------------------------------------
; benOS Common Loaders - Move Data To benOS Launch End Stage
; ------------------------------------------------------------------

    mov esi, benos_launch_end
    mov ecx, buffer_size_sectors * 512 / 4
    cld
    a32 rep movsd

    pop ecx
    pop eax

    add eax, buffer_size_sectors
    sub ecx, buffer_size_sectors
    jmp .lp


; ------------------------------------------------------------------------------------
; benOS Common Loaders - Any Left Over Microkernel Outside The Buffer - Loads Here
; ------------------------------------------------------------------------------------

.break:
    ; load the part of the kernel that does not fill the buffer completely
    test ecx, ecx
    jz .finish ; if cx = 0 => skip

    push ecx
    push edi

    mov bx, benos_launch_end
    mov dx, 0x0
    call load


; ------------------------------------------------------------------
; benOS Common Loaders - Moving Remnants Of Microkernel
; ------------------------------------------------------------------

    call ben_unreal

    pop edi
    pop ecx

    mov esi, benos_launch_end
    shl ecx, 7 ; * 512 / 4
    cld
    a32 rep movsd


; ------------------------------------------------------------------
; benOS Common Loaders - Finalization Of Common Bootloader Stage
; ------------------------------------------------------------------


.finish:
    call print_line
    ret


; ------------------------------------------------------------------
; benOS Common Loaders - Common Imports 
; 'benconfig.asm' - benOS Bootloader Configuration
; 'ben_df.asm' - benOS Bootloader Diffs
; 'global_descriptor_table_entry.inc' - benOS GDTE 
; 'ben_ur.asm' - benOS Bootloader Unreal Mode
; 'ben_mm.asm' - benOS Bootloader Memory Mapping 
; 'benplay.asm' - benOS BenPlay Bootloader Video Config / Driver Loader
; 'startup_ben.asm' - benOS Bootloader Launcher
; 'benfs.asm' - benOS Local FileSystem
; ------------------------------------------------------------------

%include "benconfig.asm"
%include "ben_df.inc"
%include "global_descriptor_table_entry.inc"
%include "ben_ur.asm"
%include "ben_mm.asm"
%include "benplay.asm"
%include "startup_ben.asm"
%ifndef KERNEL
    %include "benfs.asm"
%endif

init_fpu_msg: db "Initialize FPU",13,10,0
init_sse_msg: db "Initialize SSE",13,10,0
init_pit_msg: db "Initialize PIT",13,10,0
init_pic_msg: db "Initialize PIC",13,10,0
startup_ben_arch_msg: db "Startup benOS Arch",13,10,0
