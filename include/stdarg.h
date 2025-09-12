//
// Created by wang on 25-9-11.
//

#ifndef SRDARG_H
#define SRDARG_H
typedef char* va_list ;
// 将p指向count中不变参数
#define va_start(p,count)(p = (va_list)&count +  sizeof(char*))
// 将p自增类型长度后减去自增数返回 (ziya老师这个地方写的是char*  写死32位下的四个字节 用无符号的 longlong 会轧钢)
#define va_arg(p,type)(*(type*)((p += sizeof(type)) - sizeof(type)))
// 释放p
#define va_end(p) (p=0)

#endif //SRDARG_H
