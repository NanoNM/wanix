//
// Created by wang on 25-9-12.
//
#include "../include/wanux/kernel.h"
#include "../include/wanux/tty.h"
#include "../include/asm/system.h"

static char buf[1024];

int printk(const char * fmt, ...) {
    CLI

    va_list args;
    int i;

    va_start(args, fmt);

    i = vsprintf(buf, fmt, args);

    va_end(args);

    console_write(buf, i);

    STI

    return i;
}