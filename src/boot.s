global start

section .text
bits 32
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

main:
    ; print `OK` to screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt

check_multiboot:
    ; Multiboot specification states that a compliant bootloader must write
    ; magic value 0x36d76289 to EAX before loading a kernel.
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error

check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing

    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit wasn't
    ; flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    ; Test if extended processor info is available.
    mov eax, 0x80000000 ; Argument to query highest supported cpuid argument
    cpuid               ; which gets passed back in EAX.
    cmp eax, 0x80000001 ; CPU is too old for long mode if returned max
    jb .no_long_mode    ; supported argument is not at least 0x80000001.

    ; Use extended info to test if long mode is available
    mov eax, 0x80000001 ; Argument for extended processor info
    cpuid               ; Returns various feature bits in ecx and edx
    test edx, 1 << 29   ; Test if the LM-bit is set in the D-Register
    jz .no_long_mode    ; If it's not set, there is no long mode
    ret
.no_long_mode:
    mov al, "2"
    jmp error

; Print "ERR: <error code>" to screen and hang
; param: error code (ascii) in al
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte [0xb800a], al
    hlt

section .bss
stack_bottom:
    resb 64
stack_top:
