/* Route compiled memref malloc/free calls through the model workspace.
 * Before gemcc_model_init, callers still use the platform allocator for
 * input/output/workspace setup.  Link with --wrap=malloc --wrap=free. */
#include "gemcc_model.h"

#include <stddef.h>

void *__real_malloc(size_t bytes);
void __real_free(void *ptr);

void *__wrap_malloc(size_t bytes) {
  if (gemcc_workspace_is_bound())
    return gemcc_workspace_alloc(bytes);
  return __real_malloc(bytes);
}

void __wrap_free(void *ptr) {
  if (gemcc_workspace_owns(ptr)) {
    gemcc_workspace_free(ptr);
    return;
  }
  __real_free(ptr);
}
