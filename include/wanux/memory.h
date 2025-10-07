//
// Created by wang on 25-10-7.
//

#ifndef MEMORY_H
#define MEMORY_H
typedef struct {
    unsigned int  base_addr_low;    //内存基地址的低32位
    unsigned int  base_addr_high;   //内存基地址的高32位
    unsigned int  length_low;       //内存块长度的低32位
    unsigned int  length_high;      //内存块长度的高32位
    unsigned int  type;             //描述内存块的类型
}check_memmory_item_t;

typedef struct {
    unsigned short          times;
    check_memmory_item_t*   data;
}check_memory_info_t;

void printMemInfo();
#endif //MEMORY_H
