#include "c_layer.h"

static struct context context;

FLOW_API void initialize(frame_callback frame_callback)
{
  context.frame_callback = frame_callback;
  context.size = 2;
  *context.image_bytes = malloc(context.size * context.size * 4);
}

FLOW_API void randomScreen(uint64_t seed) {
  for (int index = 0; index < context.size * context.size * 4; index += 4) {
    context.image_bytes[index] = 51 * seed;
    context.image_bytes[index + 1] = 51 * seed;
    context.image_bytes[index + 2] = 51 * seed;
    context.image_bytes[index + 3] = 255;
  }

  printf("%s", "test");

  context.frame_callback(context.size, context.size, context.size * context.size * 4, &context.image_bytes);
}

