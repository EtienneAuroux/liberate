#include "c_layer.h"

static struct context context;

FLOW_API void initialize(frame_callback frame_callback, uint64_t width, uint64_t height)
{
  context.frame_callback = frame_callback;
  context.background.config = grid;
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

FLOW_API void update_background_size(uint64_t width, uint64_t height, uint64_t cycle_time, int64_t x_offset, int64_t y_offset)
{
  context.background.width = width;
  context.background.height = height;
  draw_background(cycle_time, x_offset, y_offset);
}

FLOW_API void update_background_config(uint8_t config_byte)
{
  context.background.config = config_byte;
}

FLOW_API void draw_background(uint64_t cycle_time, int64_t x_offset, int64_t y_offset)
{
  for (int i = 0; i < context.num_image_threads; i++)
  {
    context.image_threads[i].settings.config = context.background.config;
    context.image_threads[i].settings.cycle_time = cycle_time;
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

void image_thread_entry_point(struct image_settings *settings)
{
  configuration config = settings->config;
  switch (config) 
  {
    case grid: grid_configuration(settings); break;
    case wave: wave_configuration(settings); break;
    default: break;
  }
}

void grid_configuration(struct image_settings *settings)
{
  int square_dash_size = square_size / 3;
  int total_x_offset = settings->x_offset + square_size / 2;
  int total_y_offset = settings->y_offset + square_size / 2;

  for (int y = settings->start_row; y < settings->end_row; y++) 
  {
    int true_y = abs(y - total_y_offset) ; 
    bool horizontal_line = true_y % square_size >= 0 && true_y % square_size < square_stroke_thickness;
    bool vertical_space = (true_y + square_dash_size / 4) % square_dash_size >= 0 && (true_y + square_dash_size / 4) % square_dash_size < square_dash_size / 2;
    for (int x = 0; x < context.background.width; x++)
    {
      int true_x = abs(x - total_x_offset) ;
      bool vertical_line = true_x % square_size >= 0 && true_x % square_size < square_stroke_thickness;
      bool horizontal_space = (true_x + square_dash_size / 4) % square_dash_size >= 0 && (true_x + square_dash_size / 4) % square_dash_size < square_dash_size / 2;
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

void wave_configuration(struct image_settings *settings)
{
  double offset = 100;
  double amplitude = 30;
  double time = settings->cycle_time / 100.0;

  double angle = sin(time * 0.5) * 0.5;         // Oscillates between -0.5 and 0.5
  double frequency = 0.01 + 0.005 * sin(time);  // Oscillates between 0.005 and 0.015
  double scroll =  offset + fmod(settings->cycle_time * 0.05, context.background.width); // Smooth horizontal scroll

  struct range ranges[] = {
        {-80, 0.5},
        {-60, 1.0},
        {-40, 2.0},
        {-20, 3.0},
        {0, 4.0},
        {20, 3.0},
        {40, 2.0},
        {60, 1.0},
        {80, 1.0}
  };

  for (int y = settings->start_row; y < settings->end_row; y++)
  {
    for (int x = 0; x < context.background.width; x++)
    {
      // Compute the X position of the wave line at this Y
      double wave_x = offset + scroll + angle * y + amplitude * sin(y * frequency);
      
      bool is_index_in_any_range = false;
      int num_ranges = sizeof(ranges) / sizeof(ranges[0]);
      for (int range_index = 0; range_index < num_ranges; range_index++)
      {
        if (is_index_in_range(x, wave_x, ranges[range_index])) {
          is_index_in_any_range = true;
          break;
        }
      }

      if (is_index_in_any_range)
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

bool is_index_in_range(int index, double base, struct range range)
{
  return (index >= base + range.offset - range.tolerance && index <= base + range.offset + range.tolerance);
}

int round_double_to_int(double x)
{
  return (int)(x + 0.5 - (x<0));
}
