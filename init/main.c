
#include "../include/wanux/traps.h"
#include "../include/wanux/tty.h"
#include "../include//wanux/memory.h"
#include "../include/asm/system.h"


extern void clock_init();

int k32_entry(void) {
    console_init();
    clock_init();

    // 内存管理模块一定要放在主功能前面,因为主功能都要用到
    printMemInfo();

    gdt_init();
    idt_init();


    // task_init();
    while (true);
}


