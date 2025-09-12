//
// Created by wang on 25-9-12.
//

#ifndef TTY_H
#define TTY_H
#include "types.h"

void console_init(void);

int console_write(char *buf, u32 count);

#endif //TTY_H
