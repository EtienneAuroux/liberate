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

#define message(format, ...) log_message(log_level, __func__, __FILE__, __LINE__, format,  __VA_ARGS__);

typedef void(*frame_callback)(uint64_t width, uint64_t height, uint64_t data_size, void *data);

struct context
{
    frame_callback frame_callback;
    uint64_t size;
    uint64_t image_bytes[];
};

FLOW_API void initialize(frame_callback frame_callback);

FLOW_API void randomScreen(uint64_t seed);

