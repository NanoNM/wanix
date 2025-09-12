cmake_minimum_required(VERSION 3.28)
project(helloworld C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_FLAGS -m32)


add_executable(helloworld hellomain/helloworld.c)
