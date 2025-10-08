//
// Created by wang on 25-10-7.
//

#ifndef MEMORY_H
#define MEMORY_H

#define PAGE_SIZE 0x1000

typedef struct {
    uint  base_addr_low;    //内存基地址的低32位
    uint  base_addr_high;   //内存基地址的高32位
    uint  length_low;       //内存块长度的低32位
    uint  length_high;      //内存块长度的高32位
    uint  type;             //描述内存块的类型
}check_memmory_item_t;

typedef struct {
    unsigned short          times;
    check_memmory_item_t*   data;
}check_memory_info_t;

// 物理内存映射结构体

typedef struct {
    uint    addr_start_low;     // 可用内存起始地址 一般是1M
    uint    addr_start_high;     // 可用内存起始地址 一般是1M

    uint    addr_end_low;       // 可用内存结束地址
    uint    addr_end_high;

    uint    valid_mem_size;

    uint    pages_total;    // 机器物理内存共多少page
    uint    pages_free;     // 机器物理内存还剩多少page
    uint    pages_used;     // 机器物理内存用了多少page
}physics_memory_info_t;

typedef struct {
    uint            addr_base;          // 可用物理内存开始位置  3M
    uint            pages_total;        // 共有多少page   机器物理内存共多少page - 0x30000（3M）
    uint            bitmap_item_used;   // 如果1B映射一个page，用了多少个page
    uchar*          map;
}physics_memory_map_t;

void printMemInfo();
void mem_init();
void mem_map_init();
void* get_free_page();
void free_page(void* p);


void* virtual_memory_init();
#endif //MEMORY_H
