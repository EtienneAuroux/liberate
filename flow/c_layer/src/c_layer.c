#include "c_layer.h"

static struct context context;

FLOW_API void initialize(frame_callback frame_callback)
{
  context.frame_callback = frame_callback;
  context.background.height = 100;
  context.background.width = 200;
  context.background.pixels = malloc(context.background.height * context.background.width * sizeof(struct rgba));
}

FLOW_API void randomScreen(uint64_t seed) {
  for (int pixel_index = 0; pixel_index < context.background.height * context.background.width; pixel_index++)
  {
    context.background.pixels[pixel_index] = (struct rgba){51 * seed, 41 * seed, 31 * seed, 255};
  }

  context.frame_callback(context.background.width, context.background.height, context.background.width * context.background.height * sizeof(struct rgba), context.background.pixels);
}

