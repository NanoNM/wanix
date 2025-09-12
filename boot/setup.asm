; ==============================================================================
; setup.asm - 16位实模式下的系统初始化程序（加载内核、检测内存、进入保护模式）
; 程序加载地址：0x5C00（由引导程序 boot.asm 指定）
; ==============================================================================
[ORG 0x500]   ; 程序被读取到内存 0x5C00 处执行
[BITS 16]      ; 明确指定 16位实模式

; ==============================================================================
; 1. 数据段：定义常量、内存检测缓冲区、GDT 表
; ==============================================================================
[SECTION .setup_data]
KERNEL_ADDR equ 0x7000
; --------------------------
; 内存检测相关常量/变量
; --------------------------
ARDS_TIMES_ADDR   equ 0x1100  ; 存储 ARDS 结构数量（1字节）
ARDS_BUFFER_ADDR  equ 0x1102  ; 存储 ARDS 结构的缓冲区起始地址
ARDS_TIMES        dw 0        ; ARDS 结构计数（初始为0）

; --------------------------
; GDT（全局描述符表）相关常量/变量
; --------------------------
SEGLIMIT          equ 0xfffff ; 段限长（4KB粒度下对应 4GB 内存）
BASEADDR          equ 0x0     ; 段基地址（从 0x0 开始）
GDT_CODE_SEGMENT  equ (1 << 3); 代码段选择子（索引1，RPL=0）
GDT_DATA_SEGMENT  equ (2 << 3); 数据段选择子（索引2，RPL=0）

; GDT 表实体（共3个描述符：空描述符、代码段、数据段）
gdt_header:       ; 空描述符（必须存在，占位用）
    dd 0, 0       ; 8字节空数据

code_gdt:         ; 32位代码段描述符（8字节）
    dw  SEGLIMIT & 0xFFFF           ; 段限长：低16位
    dw  BASEADDR & 0xFFFF           ; 基地址：低16位
    db  (BASEADDR >> 16) & 0xFF     ; 基地址：中8位（16-23位）
    db  0b1_00_1_1010               ; 访问权限字节
                                    ; P=1(存在) | DPL=00(内核级) | S=1(代码/数据段)
                                    ; Type=1010(代码段 | 可读 | 非一致 | 已访问)
    db  0b1_1_0_0_0000 | (SEGLIMIT >> 16) & 0xF  ; 高4位属性 + 段限长（16-19位）
                                    ; G=1(4KB粒度) | D/B=1(32位模式) | L=0(非64位) | AVL=0
    db  (BASEADDR >> 24) & 0xFF     ; 基地址：高8位（24-31位）

data_gdt:         ; 32位数据段描述符（8字节）
    dw  SEGLIMIT & 0xFFFF           ; 段限长：低16位
    dw  BASEADDR & 0xFFFF           ; 基地址：低16位
    db  (BASEADDR >> 16) & 0xFF     ; 基地址：中8位（16-23位）
    db  0b1_00_1_0010               ; 访问权限字节
                                    ; P=1(存在) | DPL=00(内核级) | S=1(代码/数据段)
                                    ; Type=0010(数据段 | 可写 | 向上扩展)
    db  0b1_1_00_0000 | (SEGLIMIT >> 16) & 0xF  ; 高4位属性 + 段限长（16-19位）
                                    ; G=1(4KB粒度) | D/B=1(32位模式) | L=0(非64位) | AVL=0
    db  (BASEADDR >> 24) & 0xFF     ; 基地址：高8位（24-31位）

; GDT 描述符（LGDT 指令需读取此结构）
gdt_pointer:
    dw  $ - gdt_header - 1  ; GDT 表长度（总字节数 - 1）
    dd  gdt_header          ; GDT 表起始地址（实模式下为物理地址）

; --------------------------
; 字符串常量（打印用）
; --------------------------
msg:
    db "Hello world. setup load success. loading to protected mode", 10, 13, 0
    ; 10=换行符（LF），13=回车符（CR），0=字符串结束符（NULL）

MEM_CHEAK_ERROR:
    db "MEM_CHEAK_ERROR", 10, 13, 0  ; 内存检测失败提示

MEM_CHEAK_SUCCESS:
    db "MEM_CHEAK_SUCCESS", 10, 13, 0; 内存检测成功提示

SETUP_BOOT_INTO_KERNEL:
    db "SETUP_BOOTING_INTO_KERNEL", 10, 13, 0; 内存检测成功提示


; ==============================================================================
; 2. 代码段：程序入口、核心逻辑（内存检测、读内核、进入保护模式）
; ==============================================================================
[SECTION .text]
global setup_start  ; 导出入口符号，供链接器识别

; --------------------------
; 程序入口点
; --------------------------
setup_start:
    ; 初始化段寄存器（实模式下段基地址均为 0x0）
    mov ax, 0
    mov ds, ax    ; 数据段寄存器
    mov ss, ax    ; 栈段寄存器
    mov es, ax    ; 附加段寄存器
    mov fs, ax    ; 额外段寄存器
    mov gs, ax    ; 额外段寄存器
    mov si, ax    ; 源变址寄存器（初始化用）

    ; 打印初始化成功信息
    mov si, msg
    call print

    ; 核心流程：1.检测内存 -> 2.进入保护模式
    call mem_cheak          ; 内存检测（获取内存布局）
    mov si, SETUP_BOOT_INTO_KERNEL
    call print
; 步骤1：关闭中断（防止切换过程中被中断打断）
    cli

    ; 步骤2：加载 GDT 表（LGDT 指令：将 GDT 描述符加载到 GDTR 寄存器）
    lgdt [gdt_pointer]

    ; 步骤3：开启 A20 地址线（支持 1MB 以上内存访问）
    in al, 0x92        ; 读取 0x92 端口（系统控制端口）
    or al, 00000010b   ; 置第1位为1（开启 A20 地址线）
    out 0x92, al       ; 写回端口

    ; 步骤5：置 CR0 寄存器 PE 位（第0位），进入保护模式
    mov eax, cr0
    or eax, 1          ; PE 位 = 1（Protection Enable，保护模式使能）
    mov cr0, eax

    call enter_protected_mod; 准备并进入32位保护模式


    jmp $  ; 死循环（防止程序意外跑飞）


; ==============================================================================
; 子函数1：内存检测（通过 BIOS 0x15 中断获取内存布局）
; 功能：读取系统内存分布，存储 ARDS 结构到缓冲区
; 输出：ARDS_TIMES_ADDR = ARDS 结构数量；ARDS_BUFFER_ADDR = ARDS 结构缓冲区
; ==============================================================================
mem_cheak:
    mov di, ARDS_BUFFER_ADDR  ; DI 指向 ARDS 缓冲区起始地址
    xor ebx, ebx              ; EBX = 0（首次调用 0x15 中断需置0）

.mem_cheak_loop:
    ; 调用 BIOS 0x15 中断（功能号 0xE820，获取内存布局）
    mov edx, 0x534D4150  ; 魔术字 "SMAP"（必须传入，标识请求类型）
    mov eax, 0xE820       ; 功能号：获取系统内存映射
    mov ecx, 20           ; ARDS 结构大小（20字节，兼容大多数BIOS）
    int 0x15              ; 触发中断

    ; 检查中断执行结果（CF=1 表示错误）
    jc .mem_cheak_error   ; CF=1 → 内存检测失败，跳转到错误处理

    ; 更新 ARDS 计数和缓冲区指针
    add di, cx            ; 缓冲区指针后移（跳过当前 ARDS 结构）
    inc dword [ARDS_TIMES]; ARDS 结构数量 + 1

    ; 检查是否还有更多 ARDS 结构（EBX=0 表示结束）
    or ebx, ebx
    jnz .mem_cheak_loop   ; EBX≠0 → 继续读取下一个 ARDS 结构

    ; 内存检测成功：保存 ARDS 数量，打印成功信息
    mov al, [ARDS_TIMES]
    mov [ARDS_TIMES_ADDR], al  ; 存储 ARDS 数量到指定地址
    mov si, MEM_CHEAK_SUCCESS
    call print

    ret  ; 返回主程序


; 内存检测错误处理（死循环，防止程序继续执行）
.mem_cheak_error:
    mov si, MEM_CHEAK_ERROR
    call print
    jmp $  ; 死循环


; ==============================================================================
; 子函数2：进入32位保护模式（核心步骤：关中断、加载GDT、开A20、置CR0位）
; 功能：完成实模式到保护模式的切换，并读取内核到内存
; ==============================================================================
enter_protected_mod:
    mov edi, KERNEL_ADDR
    mov ecx, 3         ; LBA 扇区号 = 2（内核存储起始扇区）
    mov bl, 100         ; 读取扇区数 = 100（内核大小对应100个扇区）
    call .lba_read     ; 调用 LBA 读硬盘函数

    ;跳转到载入位置
    jmp GDT_CODE_SEGMENT:KERNEL_ADDR
    jmp $  ; 死循环（备用，防止跳转失败）


; ==============================================================================
; 子函数3：LBA 模式读硬盘扇区（实模式下访问 IDE 硬盘）
; 功能：从指定 LBA 扇区读取指定数量的扇区到内存
; 输入：ECX = LBA 扇区号；BL = 读取扇区数；目标地址 = 0x1200
; 输出：扇区数据写入到 0x1200 起始地址
; ==============================================================================
.lba_read:

    ; 1. 设置读取扇区数（IDE 端口 0x1F2）
    mov dx, 0x1F2    ; 0x1F2 = 扇区计数寄存器
    mov al, bl       ; AL = 读取扇区数（BL 传入）
    out dx, al       ; 写端口

    ; 2. 设置 LBA 扇区号（低8位，端口 0x1F3）
    inc dx           ; 0x1F3 = LBA 低8位寄存器
    mov al, cl       ; AL = LBA[7:0]（ECX 低8位）
    out dx, al

    ; 3. 设置 LBA 扇区号（中8位，端口 0x1F4）
    inc dx           ; 0x1F4 = LBA 中8位寄存器
    mov al, ch       ; AL = LBA[15:8]（ECX 中8位）
    out dx, al

    ; 4. 设置 LBA 扇区号（高8位，端口 0x1F5）
    inc dx           ; 0x1F5 = LBA 高8位寄存器
    shr ecx, 16      ; ECX 右移16位，提取 LBA[23:16]
    mov al, cl       ; AL = LBA[23:16]
    out dx, al

    ; 5. 设置驱动器/头部（端口 0x1F6）：主盘 + LBA 模式 + LBA[27:24]
    inc dx           ; 0x1F6 = 驱动器/头部寄存器
    shr ecx, 8       ; ECX 右移8位，提取 LBA[27:24]
    or al, 0xE0      ; 0xE0 = 11100000B（主盘 | LBA 模式）
    out dx, al

    ; 6. 发送读命令（端口 0x1F7）
    inc dx           ; 0x1F7 = 命令/状态寄存器
    mov al, 0x20     ; 0x20 = 读扇区命令（无重试）
    out dx, al

    ; 7. 等待硬盘就绪（检查状态寄存器）
    call .wait_ready

    ; 8. 读取数据到内存（目标地址 0x1200，每次读2字节）
    mov di, KERNEL_ADDR   ; DI = 目标内存地址（内核加载地址）

    mov cl, bl
    xchg bx,bx
    xchg bx,bx

.start_read:
    push cx
    call .wait_ready
    call .read_hd
    pop cx
    loop .start_read
.return:
    ret

.read_hd:
    mov cx, 256
    mov dx, 0x1F0    ; 0x1F0 = 数据端口（双向）

.read_word:
    in ax, dx
    mov [edi], ax
    add edi, 2
    loop .read_word

    ret

; ==============================================================================
; 子函数4：等待硬盘就绪（辅助 .lba_read 函数）
; 功能：检查 IDE 硬盘状态寄存器，直到硬盘空闲且数据就绪
; ==============================================================================
.wait_ready:
    mov dx, 0x1F7    ; 0x1F7 = 命令/状态寄存器

.wait_loop:
    in al, dx        ; 读取状态寄存器
    test al, 0x80    ; 检查忙标志（第7位：1=忙，0=空闲）
    jnz .wait_loop   ; 忙 → 继续等待

    test al, 0x08    ; 检查数据就绪标志（第3位：1=就绪，0=未就绪）
    jz .wait_loop    ; 未就绪 → 继续等待

    ret   ; 就绪 → 返回


; ==============================================================================
; 子函数5：BIOS 打印字符串（实模式下用 0x10 中断）
; 功能：打印以 NULL 结尾的字符串到屏幕
; 输入：SI = 字符串起始地址（DS:SI 指向字符串）
; ==============================================================================
print:
    mov ah, 0x0E    ; BIOS 0x10 中断功能号：Teletype 输出（光标跟随）
    mov bh, 0x00    ; 显示页号（默认第0页）
    mov bl, 0x07    ; 字符颜色（黑底白字，0x07 为默认属性）

.loop:
    lodsb           ; 从 DS:SI 读1字节到 AL，SI 自动 +1
    or al, al       ; 检查是否为字符串结束符（AL=0 → 结束）
    jz .print_end   ; 结束符 → 退出打印
    int 0x10        ; 触发 0x10 中断，打印当前字符
    jmp .loop       ; 继续打印下一个字符

.print_end:
    ret   ; 返回调用者