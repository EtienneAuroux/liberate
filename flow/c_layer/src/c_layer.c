#include "c_layer.h"

static struct context context;

FLOW_API void initialize(frame_callback frame_callback, uint64_t width, uint64_t height)
{
  context.frame_callback = frame_callback;
  context.background.width = width;
  context.background.height = height;

  // Allocate threads
  context.num_image_threads = 4;
  context.image_threads = malloc(context.num_image_threads * sizeof(struct image_thread));

  // black
  context.colors.background_color = (struct rgba){0, 0, 0, 0};
  // amber
  context.colors.line_color = (struct rgba){255, 192, 0, 0};
  
  context.background.pixels = malloc(context.background.height * context.background.width * sizeof(struct rgba));
}

FLOW_API void update_background_size(uint64_t width, uint64_t height, double zoom, int64_t x_offset, int64_t y_offset)
{
  context.background.width = width;
  context.background.height = height;
  draw_background(zoom, x_offset, y_offset);
}

FLOW_API void draw_background(double zoom, int64_t x_offset, int64_t y_offset)
{
  for (int i = 0; i < context.num_image_threads; i++)
  {
    context.image_threads[i].settings.zoom = zoom;
    context.image_threads[i].settings.x_offset = x_offset;
    context.image_threads[i].settings.y_offset = y_offset;
    context.image_threads[i].settings.start_row = i * context.background.height / context.num_image_threads;
    context.image_threads[i].settings.end_row = (i + 1) * context.background.height / context.num_image_threads;

    thrd_create(&context.image_threads[i].thread, image_thread_entry_point, &context.image_threads[i].settings);
  }

  for (int i = 0; i < context.num_image_threads; i++)
  {
    thrd_join(context.image_threads[i].thread, NULL);
  }
  
  context.frame_callback(context.background.width, context.background.height, context.background.width * context.background.height * sizeof(struct rgba), context.background.pixels);
}

FLOW_API void image_thread_entry_point(struct image_settings *settings)
{
  int total_x_offset = settings->x_offset + square_size / 2;
  int total_y_offset = settings->y_offset + square_size / 2;

  for (int y = settings->start_row; y < settings->end_row; y++) 
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
}
