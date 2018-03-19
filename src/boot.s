global start

section .text
bits 32
start:
    mov esp, stack_top

    ; print `OK` to screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt

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
