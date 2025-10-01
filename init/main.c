
#include "../include/asm/io.h"
#include "../include/stdarg.h"
#include "../include/wanux/kernel.h"
#include "../include/wanux/traps.h"
#include "../include/asm/system.h"
#include "../include/wanux/tty.h"
#include "../include/common.h"

typedef struct {
    unsigned int  base_addr_low;    //内存基地址的低32位
    unsigned int  base_addr_high;   //内存基地址的高32位
    unsigned int  length_low;       //内存块长度的低32位
    unsigned int  length_high;      //内存块长度的高32位
    unsigned int  type;             //描述内存块的类型
}check_memmory_item_t;

typedef struct {
    unsigned short          times;
    check_memmory_item_t*   data;
}check_memory_info_t;



void printMemInfo(){
    printk("====== memory check info =====\n");

    check_memory_info_t* p = (check_memory_info_t*)ARDS_ADDR;
    check_memmory_item_t* p_data = (check_memmory_item_t*)(ARDS_ADDR + 2);

    unsigned short times = p->times;

    printk("%d\n",times);
    for (int i = 0; i < times; ++i) {
        check_memmory_item_t* tmp = p_data + i;

        printk("\t %x,\t %x,\t %x,\t %x,\t %d\n", tmp->base_addr_high, tmp->base_addr_low,
               tmp->length_high, tmp->length_low, tmp->type);
    }
    printk("====== memory check info =====\n");

}

int k32_entry(void) {
    console_init();

    // clock_init();

    // 内存管理模块一定要放在主功能前面,因为主功能都要用到
    // print_check_memory_info();
    // memory_init();
    printMemInfo();

    gdt_init();
    idt_init();
    __asm__("sti;");

    // task_init();


    while (true);
}


