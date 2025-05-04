#include "c_layer.h"

static struct context context;

FLOW_API void initialize(frame_callback frame_callback, uint64_t width, uint64_t height)
{
  context.frame_callback = frame_callback;
  context.background.width = width;
  context.background.height = height;

  // Initialize the mutex
  mtx_init(&context.mutex, mtx_plain);

  // black
  context.colors.background_color = (struct rgba){0, 0, 0, 0};
  // amber
  context.colors.line_color = (struct rgba){255, 192, 0, 0};
  
  context.background.pixels = malloc(context.background.height * context.background.width * sizeof(struct rgba));
}

FLOW_API void randomScreen(uint64_t seed) 
{
  for (int pixel_index = 0; pixel_index < context.background.height * context.background.width; pixel_index++)
  {
    context.background.pixels[pixel_index] = (struct rgba){51 * seed, 41 * seed, 31 * seed, 255};
  }

  context.frame_callback(context.background.width, context.background.height, context.background.width * context.background.height * sizeof(struct rgba), context.background.pixels);
}

FLOW_API void draw_background(double zoom, int64_t x_offset, int64_t y_offset)
{
  struct image_settings settings;
  settings.zoom = zoom;
  settings.x_offset = x_offset;
  settings.y_offset = y_offset;
  
  thrd_create(&context.thread, thread_entry_point, &settings);
  
  thrd_join(context.thread, NULL);
  
  context.frame_callback(context.background.width, context.background.height, context.background.width * context.background.height * sizeof(struct rgba), context.background.pixels);
}

FLOW_API void thread_entry_point(struct image_settings *settings)
{
  if (mtx_trylock(&context.mutex) == thrd_busy)
  {
    return;
  }

  int true_x_offset = settings->x_offset % square_size;
  int true_y_offset = settings->y_offset % square_size;
  

  for (int y = 0; y < context.background.height; y++) 
  {
    int y_position = true_y_offset == 0 ? 0 : y % true_y_offset;
    bool y_ok = y_position >= square_size - square_stroke_thickness / 2 || y_position < square_stroke_thickness;
    // bool y_ok = (y + settings->y_offset + square_size / 2) % square_size >= square_size - square_stroke_thickness / 2 || (y + settings->y_offset + square_size / 2) % square_size <= square_stroke_thickness / 2;
    bool y_spaces = y % (2 * square_stroke_spacing) <= square_stroke_spacing;

    for (int x = 0; x < context.background.width; x++)
    {
      int x_position = true_x_offset == 0 ? 0 : x % true_x_offset;
      bool x_ok = x_position >= square_size - square_stroke_thickness / 2 || x_position < square_stroke_thickness;
      // bool x_ok = (x + settings->x_offset + square_size / 2) % square_size >= square_size - square_stroke_thickness / 2 || (x + settings->x_offset + square_size / 2) % square_size <= square_stroke_thickness / 2;
      bool x_spaces = x % (2 * square_stroke_spacing) <= square_stroke_spacing;
      if ((y_ok && x_spaces) || (x_ok && y_spaces))
      {
        context.background.pixels[y * context.background.width + x] = context.colors.line_color;
      }
      else
      {
        context.background.pixels[y * context.background.width + x] = context.colors.background_color;
      }
    }
  }

  mtx_unlock(&context.mutex);
}
