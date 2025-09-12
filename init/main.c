
#include "../include/asm/io.h"
#include "../include/stdarg.h"
#include "../include/wanux/kernel.h"
#include "../include/asm/system.h"
#include  "../include/wanux/tty.h"


int k32_entry(void) {

    // while(1);
    console_init();
    char * osname= "wanix";
    printk("welcome to %s\n",osname);

    // __asm__("sti;");

    while(1);

}
