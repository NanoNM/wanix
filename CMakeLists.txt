cmake_minimum_required(VERSION 3.28)
project(helloworld C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_FLAGS -m32)


add_executable(helloworld helloworld/helloworld.c
        kernel/traps.c
        kernel/chr_drv/easy_keybord.c
        kernel/chr_drv/clock.c
        mm/memory.c
        include/wanux/memory.h
)
