#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <threads.h>
#include <math.h>

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

typedef enum
{
    grid,
    wave
} configuration;

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
    configuration config;
    uint64_t cycle_time;
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

FLOW_API void update_background_size(uint64_t width, uint64_t height, int64_t x_offset, int64_t y_offset);

FLOW_API void draw_background(uint64_t cycle_time, int64_t x_offset, int64_t y_offset);

void image_thread_entry_point(struct image_settings *settings);

void grid_configuration(struct image_settings *settings);

void wave_configuration(struct image_settings *settings);

int round_double_to_int(double x);
