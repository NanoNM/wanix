//
// Created by wang on 25-10-8.
//
#include "../include/asm/system.h"
#include "../include/wanux/kernel.h"
#include "../include/wanux/memory.h"

#include "../include/string.h"

/**
 *  一个pdt 4k 0x1000
 *  4g内存需要这么大页表来完整映射内存：0x1000 * 0x1000 + 0x1000
 */

// 页表从0x20000开始存
#define PDT_START_ADDR 0x20000

// 线性地址从2M开始用
#define VIRTUAL_MEM_START 0x200000

// extern task_t* current;

void* virtual_memory_init() {
    // 映射内核区域
    int *pdt = PDT_START_ADDR;
    memset(pdt,0,PAGE_SIZE);

    // pde = ptt + 尾12位
    for (int i = 0; i < 4; ++i) {
        // pdt里面的每项，即pde，内容是ptt + 尾12位的权限位

    }

}
