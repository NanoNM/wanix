;---------------------
;32位代码段入口 准备载入内核
;---------------------
[SECTION .text]
[BITS 32]
extern k32_entry

global _start

_start:
;-----------------------
;初始化栈 跳转到c代码
;-----------------------
    call k32_entry
    ;mov ax,(2 << 3)
    ;mov ds,ax
    ;mov ss,ax
    ;mov es,ax
    ;mov fs,ax
    ;mov gs,ax
    ;bootloader已经结束了他的任务， 现在把0x7c00内存 分配给操作系统
    ;mov esp, 0x7C00
    ;xchg bx,bx
    ;mov byte [0x100000],1
    jmp $