//
// Created by wang on 25-10-7.
//

#include "../include/wanux/kernel.h"
#include "../include/asm/system.h"
#include "../include/wanux/memory.h"

void printMemInfo(){
    printk("====== memory check info =====\n");

    check_memory_info_t* p = (check_memory_info_t*)ARDS_ADDR;
    check_memmory_item_t* p_data = (check_memmory_item_t*)(ARDS_ADDR + 2);

    unsigned short times = p->times;
    for (int i = 0; i < times; ++i) {
        check_memmory_item_t* tmp = p_data + i;

        printk("\t %x,\t %x,\t %x,\t %x,\t %d\n", tmp->base_addr_high, tmp->base_addr_low,
               tmp->length_high, tmp->length_low, tmp->type);
    }
    printk("====== memory check info =====\n");

}