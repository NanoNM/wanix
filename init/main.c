
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
    mem_init();
    mem_map_init();
    gdt_init();
    idt_init();

    void * a = get_free_page();
    get_free_page();
    void * b = get_free_page();
    get_free_page();
    get_free_page();

    free_page(b);
    free_page(a);

    get_free_page();
    get_free_page();
    get_free_page();
    get_free_page();

    // task_init();
    while (true);
}


