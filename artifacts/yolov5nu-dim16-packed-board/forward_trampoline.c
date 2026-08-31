/* Generated.  Calls compiled @forward; not a layer interpreter. */
#include "gemcc_model.h"

void forward(void *input, void *output);

int gemcc_model_forward(const void *input, void *output) {
  if (!input || !output)
    return -1;
  forward((void *)input, output);
  return 0;
}
