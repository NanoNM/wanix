[ORG 0x5C00]   ; 程序将被读取到 0x5C00 执行
[SECTION .text]
[BITS 16]

global _start
_start:

    ; 2. 打印字符串
    mov si, msg
    call .print
    jmp $  ; 死循环，防止程序跑飞

    ; --------------------------
    ; 子函数：打印字符串
    ; --------------------------
.print:
    mov ah, 0x0E  ; BIOS 视频功能：Teletype 输出
    mov bh, 0x00  ; 显示页号
    mov bl, 0x07  ; 颜色：黑底白字
.loop:
    lodsb         ; 从 si 读1字节到 al，si 自动+1
    or al, al     ; 判断是否到字符串结尾（0）
    jz .print_end
    int 0x10      ; 打印字符
    jmp .loop
.print_end:
    ret

    ; --------------------------
    ; 数据区：要打印的字符串
    ; --------------------------
msg:
    db "Hello world. setup load success", 10, 13, 0  ; 10=换行，13=回车，0=结束符

