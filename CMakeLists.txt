cmake_minimum_required(VERSION 3.28)
project(helloworld C)

set(CMAKE_C_STANDARD 11)

add_executable(helloworld init/main.c)
