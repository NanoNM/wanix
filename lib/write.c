//
// Created by wang on 25-9-12.
//
#include "../include/unistd.h"

_syscall3(int, write, int, fd, const char *, buf, int, count)