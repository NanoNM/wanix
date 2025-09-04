[ORG 0x5C00]   ; 程序将被读取到 0x5C00 执行
;    xchg bx,bx
;    xchg bx,bx
[SECTION .setup_data]
[BITS 16]
ARDS_TIMES_ADDR equ 0x1100
ARDS_BUFFER_ADDR equ 0x1102
ARDS_TIMES dw 0

[SECTION .gdt_data]
SEGLIMIT equ 0xfffff
BASEADDR equ 0x0
GDT_CODE_SEGMENT equ (1 << 3)
GDT_DATA_SEGMENT equ (2 << 3)

    ;---------------------------
    ; 制作GDT表
    ;---------------------------
gdt_header:
    dd 0,0
code_gdt:
    ; 构造32位代码段描述符（8字节）
    dw  SEGLIMIT & 0xFFFF           ; 段限长低16位
    dw  BASEADDR & 0xFFFF           ; 基地址低16位
    db  (BASEADDR >> 16) & 0xFF     ; 基地址中8位
    db  0b1_00_1_1010                  ; 访问权限字节
                                    ; P=1(存在), DPL=00(内核级), S=1(代码/数据段)
                                    ; Type=1010(代码段,可读,非一致,已访问)
    db  0b1_1_0_0_0000 | (SEGLIMIT >> 16) & 0xF  ; 高4位属性 + 段限长高4位
                                    ; G=1(4KB粒度), D/B=1(32位), L=0(非64位)
                                    ; AVL=0, 段限长19-16位
    db  (BASEADDR >> 24) & 0xFF     ; 基地址高8位
data_gdt:
    ; 构造32位数据段描述符（8字节）
    dw  SEGLIMIT & 0xFFFF           ; 段限长低16位
    dw  BASEADDR & 0xFFFF           ; 基地址低16位
    db  (BASEADDR >> 16) & 0xFF     ; 基地址中8位
    db  0b1_00_1_0010                  ; 访问权限字节
                                    ; P=1(存在), DPL=00(内核级), S=1(代码/数据段)
                                    ; Type=0010(数据段,可写)
    db  0b1_1_00_0000 | (SEGLIMIT >> 16) & 0xF  ; 高4位属性 + 段限长高4位
                                    ; G=1(4KB粒度), D/B=1(32位), L=0(非64位)
                                    ; AVL=0, 段限长19-16位
    db  (BASEADDR >> 24) & 0xFF     ; 基地址高8位

;创建GDT描述符
gdt_pointer:
    dw $ - gdt_header - 1
    dd gdt_header

[SECTION .text]
[BITS 16]
global setup_start
setup_start:
    mov ax,0

    mov ds,ax
    mov ss,ax
    mov es,ax

    ;mov cs,ax
    mov fs,ax
    mov gs,ax
    mov si,ax


    ; 2. 打印字符串
    mov si, msg
    call print

    call mem_cheak
    call enter_protected_mod

    jmp $  ; 死循环，防止程序跑飞


    ;---------------------------
    ; 内存检测
    ;---------------------------
mem_cheak:
    ;mov es, 0                  ; 段寄存器清0
    mov di, ARDS_BUFFER_ADDR   ; di指向缓冲区
    xor ebx, ebx               ; ebx=0 开始首次调用

.mem_cheak_loop:
    mov edx, 0x534D4150        ; 魔术字 "SMAP"
    mov eax, 0xE820            ; 功能号：获取内存布局
    mov ecx, 20                ; ARDS结构大小（20字节）
    int 0x15

    jc .mem_cheak_error        ;判断cf表示位是否出现错误
    add di, cx                 ;di + mov ecx, 20 = di+20
    inc dword [ARDS_TIMES]
    or ebx, ebx                ;判断ebx是否为0
    jnz .mem_cheak_loop

    mov al, [ARDS_TIMES]
    mov [ARDS_TIMES_ADDR],al
    mov si, MEM_CHEAK_SUCCESS
    call print

    ret


.mem_cheak_error:
    mov si, MEM_CHEAK_ERROR
    call print
    jmp $

 ;--------------------------
 ;保护模式入口
 ;--------------------------

enter_protected_mod:

    ;关闭中断
    cli
    lgdt [gdt_pointer]

    ;开a20
    in al, 92h
    or al, 00000010b
    out 92h,al

    ;设置保护模式
    mov eax,cr0
    or eax,1
    mov cr0,eax

    jmp GDT_CODE_SEGMENT:protected_mode



    ; --------------------------
    ; 子函数：打印字符串
    ; --------------------------
print:
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
    db "Hello world. setup load success.loading to prodected mode", 10, 13, 0  ; 10=换行，13=回车，0=结束符
MEM_CHEAK_ERROR:
    db "MEM_CHEAK_ERROR", 10, 13, 0  ; 10=换行，13=回车，0=结束符
MEM_CHEAK_SUCCESS:
    db "MEM_CHEAK_SUCCESS", 10, 13, 0  ; 10=换行，13=回车，0=结束符


;---------------------
;32位代码段入口 准备载入内核
;---------------------
[SECTION .text]
[BITS 32]
protected_mode:
;-----------------------
;初始化栈
;-----------------------

    mov ax,GDT_DATA_SEGMENT
    mov ds,ax
    mov ss,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    ;bootloader已经结束了他的任务， 现在把0x7c00内存 分配给操作系统
    mov esp, 0x7C00
    xchg bx,bx
    mov byte [0x100000],1

    jmp $
