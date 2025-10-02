//
// Created by wang on 25-10-2.
//

#include "../../include/wanux/kernel.h"
#include "../../include/wanux/traps.h"

void clock_handler(int idt_index) {
    send_eoi(idt_index);

    // printk("0x%x\n",idt_index);
}
