//
// Created by wang on 25-2-12.
//

#include "../../include/asm/io.h"
#include "../../include/wanux/tty.h"
#include "../../include/string.h"

#define CRT_ADDR_REG 0x3D4 // CRT(6845)索引寄存器
#define CRT_DATA_REG 0x3D5 // CRT(6845)数据寄存器

#define CRT_START_ADDR_H 0xC // 显示内存起始位置 - 高位
#define CRT_START_ADDR_L 0xD // 显示内存起始位置 - 低位
#define CRT_CURSOR_H 0xE     // 光标位置 - 高位
#define CRT_CURSOR_L 0xF     // 光标位置 - 低位

// 修复：将内存地址定义为指针类型
#define MEM_BASE ((volatile u16 *)0xB8000)              // 显卡内存起始位置（VGA文本模式）
#define MEM_SIZE 0x4000                                // 显卡内存大小 (16KB)
#define MEM_END (MEM_BASE + (MEM_SIZE / sizeof(u16)))   // 显卡内存结束位置（按u16计算）
#define WIDTH 80                                       // 屏幕文本列数
#define HEIGHT 25                                      // 屏幕文本行数
#define ROW_SIZE (WIDTH)                               // 每行字符数（原代码的ROW_SIZE是字节数，这里调整为字符数）
#define SCR_SIZE (ROW_SIZE * HEIGHT)                   // 屏幕总字符数

#define ASCII_NUL 0x00
#define ASCII_ENQ 0x05
#define ASCII_BEL 0x07 // \a
#define ASCII_BS 0x08  // \b
#define ASCII_HT 0x09  // \t
#define ASCII_LF 0x0A  // \n
#define ASCII_VT 0x0B  // \v
#define ASCII_FF 0x0C  // \f
#define ASCII_CR 0x0D  // \r
#define ASCII_DEL 0x7F

// 修复：使用正确的指针类型
static volatile u16 *screen; // 当前显示器开始的内存位置（字符指针）
static volatile u16 *pos;    // 记录当前光标的内存位置（字符指针）
static uint x, y;            // 当前光标的坐标

// 设置当前显示器开始的位置
static void set_screen() {
    uint offset = (screen - MEM_BASE) * sizeof(u16); // 计算字节偏移量
    out_byte(CRT_ADDR_REG, CRT_START_ADDR_H);
    out_byte(CRT_DATA_REG, (offset >> 9) & 0xff);
    out_byte(CRT_ADDR_REG, CRT_START_ADDR_L);
    out_byte(CRT_DATA_REG, (offset >> 1) & 0xff);
}

static void set_cursor()
{
    uint offset = (pos - MEM_BASE) * sizeof(u16); // 计算字节偏移量
    out_byte(CRT_ADDR_REG, CRT_CURSOR_H);
    out_byte(CRT_DATA_REG, (offset >> 9) & 0xff);
    out_byte(CRT_ADDR_REG, CRT_CURSOR_L);
    out_byte(CRT_DATA_REG, (offset >> 1) & 0xff);
}

void console_clear()
{
    screen = MEM_BASE;
    pos = MEM_BASE;
    x = y = 0;
    set_cursor();
    set_screen();

    volatile u16 *ptr = MEM_BASE;
    while (ptr < MEM_END)
    {
        *ptr++ = 0x0720; // 0x07是属性(黑底白字)，0x20是空格
    }
}

// 向上滚屏
static void scroll_up()
{
    // 检查是否有足够空间直接下移
    if (screen + SCR_SIZE + ROW_SIZE < MEM_END)
    {
        volatile u16 *ptr = screen + SCR_SIZE;
        for (size_t i = 0; i < WIDTH; i++)
        {
            *ptr++ = 0x0720; // 清空新行
        }
        screen += ROW_SIZE;
        pos += ROW_SIZE;
    }
    else
    {
        // 复制屏幕内容到显存起始位置
        memcpy((void *)MEM_BASE,
               (const void *)screen,
               SCR_SIZE * sizeof(u16)); // 按字符大小计算字节数
        pos -= (screen - MEM_BASE);
        screen = MEM_BASE;
    }
    set_screen();
}

static void command_lf()
{
    if (y + 1 < HEIGHT)
    {
        y++;
        pos += ROW_SIZE;
        return;
    }
    scroll_up();
}

static void command_cr()
{
    pos -= x; // x是字符数，不是字节数
    x = 0;
}

static void command_bs()
{
    if (x)
    {
        x--;
        pos--;
        *pos = 0x0720; // 用空格覆盖
    }
}

static void command_del()
{
    *pos = 0x0720; // 用空格覆盖
}

int console_write(char *buf, u32 count)
{
    CLI

    int write_size = 0;

    char ch;
    volatile u16 *ptr = pos; // 使用u16指针操作
    while (count--)
    {
        write_size++;
        ch = *buf++;
        switch (ch)
        {
            case ASCII_NUL:
                break;
            case ASCII_BEL:
                // todo \a 响铃功能
                break;
            case ASCII_BS:
                command_bs();
                ptr = pos; // 更新指针
                break;
            case ASCII_HT:
                // 可以实现制表符功能
                break;
            case ASCII_LF:
                command_lf();
                command_cr();
                ptr = pos; // 更新指针
                break;
            case ASCII_VT:
                break;
            case ASCII_FF:
                command_lf();
                ptr = pos; // 更新指针
                break;
            case ASCII_CR:
                command_cr();
                ptr = pos; // 更新指针
                break;
            case ASCII_DEL:
                command_del();
                break;
            default:
                if (x >= WIDTH)
                {
                    x -= WIDTH;
                    pos -= ROW_SIZE;
                    command_lf();
                    ptr = pos; // 更新指针
                }

                *ptr = (0x07 << 8) | (unsigned char)ch; // 高字节是属性，低字节是字符
                ptr++;
                pos++;
                x++;
                break;
        }
    }

    set_cursor();

    STI

    return write_size;
}

void console_init(void) {
    console_clear();
}
