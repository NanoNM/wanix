//
// Created by wang on 25-10-7.
//

#include "../include/wanux/kernel.h"
#include "../include/asm/system.h"
#include "../include/wanux/memory.h"
#include "../include/string.h"

#define PAGE_SIZE 0x1000
#define VALID_MEMORY_FROM           0x100000

#define ZONE_VALID 1        // ards 可用内存区域
#define ZONE_RESERVED 2     // ards 不可用区域



physics_memory_info_t g_physics_memory;
physics_memory_map_t g_physics_memory_map;

void mem_init() {
    printk("mem_init \n");
    check_memory_info_t* p = (check_memory_info_t*)ARDS_ADDR;
    check_memmory_item_t* p_data = (check_memmory_item_t*)(ARDS_ADDR + 2);
    for (int i = 0; i < p->times; ++i) {
        check_memmory_item_t * tmp_data = p_data + i;
        if (tmp_data->base_addr_low > 0 && tmp_data->type == ZONE_VALID) {
            g_physics_memory.addr_start_low = tmp_data->base_addr_low;
            g_physics_memory.valid_mem_size = tmp_data->length_low;
            g_physics_memory.addr_end_low = tmp_data->base_addr_low + tmp_data->length_low;
        }
    }

    // 如果没有可用内存
    if (VALID_MEMORY_FROM != g_physics_memory.addr_start_low) {
        printk("[%s:%d] no valid physics memory\n", __FILE__, __LINE__);
        return;
    }

    g_physics_memory.pages_total = g_physics_memory.addr_end_low >> 12;
    g_physics_memory.pages_used = 0;
    g_physics_memory.pages_free = g_physics_memory.pages_total - g_physics_memory.pages_used;

}

void mem_map_init() {
    // 验证
    printk("maper_mem \n");
    if (VALID_MEMORY_FROM != g_physics_memory.addr_start_low) {
        printk("[%s:%d] no valid physics memory\n", __FILE__, __LINE__);
        return;
    }

    g_physics_memory_map.addr_base = (uint)VALID_MEMORY_FROM * 3;
    g_physics_memory_map.map = (uchar*)0x10000;

    // 共有这么多物理页可用
    g_physics_memory_map.pages_total = g_physics_memory.pages_total;
    printk("all usefull mem %d kb\n", (g_physics_memory.pages_total * PAGE_SIZE));
    // 清零位图 （1bit = 1页 = 4k）
    for (int i = 0; i < g_physics_memory_map.pages_total; ++i) {
        // 计算当前位所在的字节索引
        unsigned int byte_index = i / 8;
        // 计算当前位在字节中的位置（0-7）
        unsigned int bit_position = i % 8;

        // 将指定位清零（使用与非操作）
        g_physics_memory_map.map[byte_index] &= ~(1 << bit_position);

    }
    // 清零字节图
    // memset(g_physics_memory_map.map, 0, g_physics_memory_map.pages_total);
    printk("mapper_mem finished!\n");


}

void printMemInfo(){
    printk("====== memory check info =====\n");
    check_memory_info_t* p = (check_memory_info_t*)ARDS_ADDR;
    check_memmory_item_t* p_data = (check_memmory_item_t*)(ARDS_ADDR + 2);
    unsigned short times = p->times;
    for (int i = 0; i < times; ++i) {
        check_memmory_item_t* tmp = p_data + i;

        printk("\t %x,\t %x,\t %x,\t %x,\t %d\n", tmp->base_addr_high, tmp->base_addr_low,
               tmp->length_high, tmp->length_low, tmp->type);
    }
    printk("====== memory check info =====\n");

}
//位图版
void* get_free_page() {
    bool find = false;
    int i = g_physics_memory_map.bitmap_item_used;
    for (; i < g_physics_memory.pages_total; ++i) {
        // 计算该页对应的字节索引与位位置
        uint byte_index = i / 8;
        uint bit_index  = i % 8;

        // 检查该位是否为0（空闲）
        if (!(g_physics_memory_map.map[byte_index] & (1 << bit_index))) {
            // 标记该页为已使用（置1）
            g_physics_memory_map.map[byte_index] |= (1 << bit_index);
            g_physics_memory_map.bitmap_item_used++;

            void* ret = (void*)(g_physics_memory_map.addr_base + i * PAGE_SIZE);
            // 返回该页的物理地址
            printk("[%s]return: 0x%X, used: %d pages\n", __FUNCTION__, ret, g_physics_memory_map.bitmap_item_used);
            return ret;
        }
    }
    printk("memory used up!");
    return NULL;
}

void free_page(void* p) {
    if (p < (void*)g_physics_memory.addr_start_low || p > (void*)g_physics_memory.addr_end_low) {
        printk("invalid address!");
        return;
    }

    int i = (int)(p - g_physics_memory_map.addr_base) >> 12;
    uint byte_index = i / 8;
    uint bit_index  = i % 8;

    if (!(g_physics_memory_map.map[byte_index] & (1 << bit_index))) {
        printk("[%s]page: 0x%X, unused\n", __FUNCTION__, p);
        return;
    }

    // 释放页（置0）
    g_physics_memory_map.map[byte_index] &= ~(1 << bit_index);
    g_physics_memory_map.bitmap_item_used--;

    printk("[%s]return: 0x%X, used: %d pages\n", __FUNCTION__, p, g_physics_memory_map.bitmap_item_used);

}




// 字节图
// void* get_free_page() {
//     bool find = false;
//
//     int i = g_physics_memory_map.bitmap_item_used;
//     for (; i < g_physics_memory.pages_total; ++i) {
//         if (0 == g_physics_memory_map.map[i]) {
//             find = true;
//             break;
//         }
//     }
//
//     if (!find) {
//         printk("memory used up!");
//         return NULL;
//     }
//
//     g_physics_memory_map.map[i] = 1;
//     g_physics_memory_map.bitmap_item_used++;
//
//     void* ret = (void*)(g_physics_memory_map.addr_base + (i << 12));
//
//     printk("[%s]return: 0x%X, used: %d pages\n", __FUNCTION__, ret, g_physics_memory_map.bitmap_item_used);
//
//     return ret;
// }
//
// void free_page(void* p) {
//     if (p < g_physics_memory.addr_start_low || p > g_physics_memory.addr_end_low) {
//         printk("invalid address!");
//         return;
//     }
//
//     int index = (int)(p - g_physics_memory_map.addr_base) >> 12;
//
//     g_physics_memory_map.map[index] = 0;
//     g_physics_memory_map.bitmap_item_used--;
//
//     printk("[%s]return: 0x%X, used: %d pages\n", __FUNCTION__, p, g_physics_memory_map.bitmap_item_used);
// }