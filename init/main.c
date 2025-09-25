
#include "../include/asm/io.h"
#include "../include/stdarg.h"
#include "../include/wanux/kernel.h"
#include "../include/asm/system.h"
#include  "../include/wanux/tty.h"

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

#define ARDS_ADDR 0x1100

int k32_entry(void) {
    // while (true);

    // while(1);
    console_init();
    char * osname= "wanix";
    printk("welcome to %s\n",osname);

    check_memory_info_t* p = (check_memory_info_t*)ARDS_ADDR;
    check_memmory_item_t* p_data = (check_memmory_item_t*)(ARDS_ADDR + 2);

    unsigned short times = p->times;

    printk("====== memory check info =====\n");
    printk("%d\n",times);
    for (int i = 0; i < times; ++i) {
        check_memmory_item_t* tmp = p_data + i;

        printk("\t %x,\t %x,\t %x,\t %x,\t %d\n", tmp->base_addr_high, tmp->base_addr_low,
               tmp->length_high, tmp->length_low, tmp->type);
    }

    printk("====== memory check info =====\n");

    // __asm__("sti;");

    while(1);

}
