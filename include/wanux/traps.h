//
// Created by wang on 25-10-1.
//
#ifndef TRAPS_H
#define TRAPS_H
#include "header.h"

void gdt_init();
void idt_init();

void send_eoi(int idt_index);

void write_xdt_ptr(xdt_ptr_t* p, short limit, int base);

#endif //TRAPS_H
