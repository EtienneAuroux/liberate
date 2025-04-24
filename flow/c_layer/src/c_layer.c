#include "c_layer.h"

static struct context context;

FLOW_API int diff(int a, int b)
{
  return a - b;
}

FLOW_API void initialize(frame_callback frame_callback)
{
  context.frame_callback = frame_callback;
}

FLOW_API void test() {
  printf("came to test()");
  context.frame_callback(500, 500, 2500, NULL);
}

