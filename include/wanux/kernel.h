//
// Created by wang on 25-9-12.
//

#ifndef KERNEL_H
#define KERNEL_H
#include "../stdarg.h"
#include "types.h"

int vsprintf(char *buf, const char *fmt, va_list args);

int printk(const char * fmt, ...);

uint get_cr3();
void set_cr3(uint v);
void enable_page();

#endif //KERNEL_H
