
#include "../include/asm/io.h"
#include "../include/stdarg.h"
#include "../include/wanux/kernel.h"
#include  "../include/wanux/tty.h"

void hello(int num, ...) {
    va_list list;
    va_start(list,num);
    int a = sizeof(char *);
    unsigned long long v1 = va_arg(list,unsigned long long);
    unsigned long long v2 = va_arg(list,unsigned long long);
    unsigned long long v3 = va_arg(list,unsigned long long);
    va_end(list);
}

int k32_entry(void) {
    console_init();
    // printk("Hello World wanux");


    // out_byte(0x3d4,0xf);
    // unsigned char v1 = in_byte(0x3d5);
    // out_byte(0x3d4,0xe);
    // unsigned char v2 = in_byte(0x3d5);
    //
    // unsigned short p = v2 * 256 + v1;
    //
    // out_byte(0x3d4,0xf);
    // out_byte(0x3d5,0x0);
    // out_byte(0x3d4,0xe);
    // out_byte(0x3d5,0x0);

    while(1);
}
