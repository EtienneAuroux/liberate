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

  int total_x_offset = settings->x_offset + square_size / 2;
  int total_y_offset = settings->y_offset + square_size / 2;

  for (int y = 0; y < context.background.height; y++) 
  {
    int true_y = abs(y - total_y_offset) ; 
    bool horizontal_line = true_y % square_size >= 0 && true_y % square_size < square_stroke_thickness;
    bool vertical_space = (true_y + square_stroke_spacing / 4) % square_stroke_spacing >= 0 && (true_y + square_stroke_spacing / 4) % square_stroke_spacing < square_stroke_spacing / 2;
    for (int x = 0; x < context.background.width; x++)
    {
      int true_x = abs(x - total_x_offset) ;
      bool vertical_line = true_x % square_size >= 0 && true_x % square_size < square_stroke_thickness;
      bool horizontal_space = (true_x + square_stroke_spacing / 4) % square_stroke_spacing >= 0 && (true_x + square_stroke_spacing / 4) % square_stroke_spacing < square_stroke_spacing / 2;
      if ((horizontal_line && horizontal_space) || (vertical_line && vertical_space))
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
