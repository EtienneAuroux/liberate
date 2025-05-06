#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <threads.h>

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

#define square_size 150
#define square_stroke_thickness 2
#define square_stroke_spacing 50

typedef void(*frame_callback)(uint64_t width, uint64_t height, uint64_t data_size, void *data);

struct rgba
{
    uint8_t r, g, b, a;
};

struct colors
{
    struct rgba background_color;
    struct rgba line_color;
    struct rgba widget_color;
};

struct image_settings
{
    double zoom;
    uint64_t x_offset;
    uint64_t y_offset;
    uint64_t start_row;
    uint64_t end_row;
};

struct image_thread
{
    struct image_settings settings;
    thrd_t thread;
};

struct image
{
    uint64_t width, height;
    struct rgba *pixels;
};

struct context
{
    frame_callback frame_callback;
    struct colors colors;
    struct image background;
    uint8_t num_image_threads;
    struct image_thread *image_threads;
    mtx_t mutex;
};

FLOW_API void initialize(frame_callback frame_callback, uint64_t width, uint64_t height);

FLOW_API void randomScreen(uint64_t seed);

FLOW_API void draw_background(double zoom, int64_t x_offset, int64_t y_offset);

FLOW_API void thread_entry_point(struct image_settings *settings);
