[bits 32]
[SECTION .text]

extern printk
extern clock_handler

;时钟中断信号入口函数
global clock_interrupt_handler_entry
clock_interrupt_handler_entry:
    push 0x20
    call clock_handler
    add esp, 4

    iret