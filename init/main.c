
#include "../include/wanux/traps.h"
#include "../include/wanux/tty.h"
#include "../include//wanux/memory.h"


extern void clock_init();

int k32_entry(void) {
    console_init();

    // 内存管理模块一定要放在主功能前面,因为主功能都要用到
    printMemInfo();
    clock_init();
    gdt_init();
    idt_init();
    __asm__("sti;");

    // task_init();
    while (true);
}


