#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FLOW_API __declspec(dllexport)
#else
#define FLOW_API
#endif

typedef void(*frame_callback)(uint64_t width, uint64_t height, uint64_t data_size, void *data);

struct context
{
    frame_callback frame_callback;
};

FLOW_API int diff(int a, int b);

FLOW_API void initialize(frame_callback frame_callback);

FLOW_API void test();

