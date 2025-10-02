[SECTION .text]
[BITS 32]
extern k32_entry

global _start
_start:
; 配置8259a芯片，响应中断用
.config_8a59a:
    ; 向主发送ICW1
    mov al, 11h
    out 20h, al

    ; 向从发送ICW1
    out 0a0h, al

    ; 向主发送ICW2
    mov al, 20h
    out 21h, al

    ; 向从发送ICW2
    mov al, 28h
    out 0a1h, al

    ; 向主发送ICW3
    mov al, 04h
    out 21h, al

    ; 向从发送ICW3
    mov al, 02h
    out 0A1h , al

    ; 向主发送ICW4
    mov al, 003h
    out 021h, al

    ; 向从发送ICW4
    out 0A1h, al

; 屏蔽主片除键盘中断外的所有中断
.enable_8259a_main:
    mov al, 11111100b  ; 中断屏蔽寄存器（IMR）值：每一位对应一个IRQ，1=屏蔽，0=允许
                       ; 第1位=0（IRQ1，键盘中断），其余位=1（屏蔽）
    out 21h, al        ; 写入主片IMR

; 屏蔽从片所有中断
.disable_8259a_slave:
    mov al, 11111111b  ; 从片IMR：所有位=1（屏蔽所有IRQ8-IRQ15）
    out 0A1h, al       ; 写入从片IMR

    ; 调用c程序
.enter_c_word:
    call k32_entry
    jmp $