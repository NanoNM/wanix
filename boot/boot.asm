[ORG 0x7C00]
[BITS 16]

_start:
    ; 设置视频模式
    mov ax, 3
    int 0x10
    ; 显示加载信息

    mov si, MSG_LOAD
    call .print_str


    ; 设置读取参数：LBA=1，读取2个扇区
    mov ecx, 1    ; LBA扇区号=1
    mov bl, 2       ; 读取2个扇区

    call .lba_read  ; 调用LBA读取函数
    jmp 0x5C00      ; 跳转到加载的setup代码执行（修改此处）

; --------------------------
; LBA模式读取硬盘扇区
; 输入:
;   eax - LBA扇区号
;   cl  - 读取扇区数
; --------------------------
.lba_read:
    pusha
    ; 1. 设置扇区计数寄存器(0x1F2)
    mov dx, 0x1F2
    mov al, bl
    out dx, al      ; 写入要读取的扇区数
    ;现在ecx 0000 0000 0000 0001
    ; 2. 设置LBA低8位(0x1F3)
    inc dx          ; dx=0x1F3
    ;cl = 0000 0001
    mov al, cl      ; al = LBA[7:0]
    out dx, al

    ; 3. 设置LBA中8位(0x1F4)
    inc dx          ; dx=0x1F4
    ;ch = 0000 0000
    mov al, ch      ; al = LBA[15:8]
    out dx, al

    ; 4. 设置LBA高8位(0x1F5)
    inc dx          ; dx=0x1F5
    shr ecx, 16     ; eax右移16位，准备高8位
    ;ecx = 0000 0000 "0000 0000" / 0000 0000 0000 0001
    mov al, cl      ; al = LBA[23:16]
    ;cl = 0000 0000
    out dx, al

    ; 5. 设置驱动器/头部寄存器(0x1F6)
    inc dx          ; dx=0x1F6
    shr ecx, 8      ; 提取LBA[27:24]
    ;ecx =0000 0000 0000 0000 / "0000 0000"  0000 0000 0000 0001
    or al, 0xE0     ; 0xE0 = 主盘(LBA模式)
    ;0xE0 = 1110 0000
    ;ecx =0000 0000 1110 0000
    out dx, al

    ; 6. 发送读命令(0x1F7)
    inc dx          ; dx=0x1F7
    mov al, 0x20    ; 读扇区命令
    out dx, al

    ; 7. 等待读取完成
    call .wait_ready

    ; 8. 读取数据到内存(示例：0x5C00)
    mov di, 0x5C00  ; 目标内存地址
    mov cx, 512/2 * 2 ; 2个扇区(每个扇区512字节，每次读2字节)
    mov dx, 0x1F0   ; 数据端口
    rep insw        ; 批量读取数据
    popa
    ret

; --------------------------
; 等待硬盘就绪
; --------------------------
.wait_ready:
    mov dx, 0x1F7
.wait_loop:
    in al, dx       ; 读取状态寄存器
    test al, 0x80   ; 检查忙标志
    jnz .wait_loop
    test al, 0x08   ; 检查数据就绪
    jz .wait_loop
    ret

; --------------------------
; 打印字符串函数
; --------------------------
.print_str:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
.loop:
    lodsb
    or al, al
    jz .end
    int 0x10
    jmp .loop
.end:
    ret

; 数据区
MSG_LOAD db "Loading setup...", 13, 10, 0
times 510 - ($ - $$) db 0
dw 0xAA55
