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

struct rgba
{
    uint8_t r, g, b, a;
};

struct image
{
    uint64_t width, height;
    struct rgba *pixels;
};

struct context
{
    frame_callback frame_callback;
    struct image background;
};

FLOW_API void initialize(frame_callback frame_callback);

FLOW_API void randomScreen(uint64_t seed);

