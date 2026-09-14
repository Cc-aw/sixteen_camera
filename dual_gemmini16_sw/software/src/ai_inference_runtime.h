#ifndef AI_INFERENCE_RUNTIME_H
#define AI_INFERENCE_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

enum inference_status {
    INFERENCE_OK = 0,
    INFERENCE_ERR_ARGUMENT = -1,
    INFERENCE_ERR_ABI = -2,
    INFERENCE_ERR_PROFILE = -3,
    INFERENCE_ERR_INPUT = -4,
    INFERENCE_ERR_OUTPUT = -5,
    INFERENCE_ERR_STATE = -6,
    INFERENCE_ERR_EXECUTE = -7,
};

enum inference_dtype {
    INFERENCE_DTYPE_I8 = 1,
    INFERENCE_DTYPE_CUSTOM = 0xff,
};

enum inference_layout {
    INFERENCE_LAYOUT_NHWC = 1,
    INFERENCE_LAYOUT_CUSTOM = 0xff,
};

struct inference_tensor_desc {
    uint8_t dtype;
    uint8_t layout;
    uint8_t rank;
    uint8_t reserved;
    uint32_t dims[4];
    size_t bytes;
    size_t alignment;
};

struct inference_tensor_buffer {
    void *data;
    size_t bytes;
    size_t alignment;
};

struct inference_device_context {
    uint32_t hardware_profile;
    uint32_t capabilities;
};

struct inference_model_instance;
struct inference_request;

typedef int (*inference_execute_fn)(
    const struct inference_model_instance *instance,
    const struct inference_request *request);

struct inference_model_descriptor {
    uint32_t abi_version;
    uint32_t hardware_profile;
    const char *name;
    struct inference_tensor_desc input;
    struct inference_tensor_desc output;
    inference_execute_fn execute;
};

struct inference_model_instance {
    const struct inference_model_descriptor *descriptor;
    const struct inference_device_context *device;
    uint32_t opened;
};

struct inference_request {
    const struct inference_tensor_buffer *input;
    struct inference_tensor_buffer *output;
    const char *input_name;
};

int inference_model_open(
    struct inference_model_instance *instance,
    const struct inference_model_descriptor *descriptor,
    const struct inference_device_context *device);
int inference_model_run(struct inference_model_instance *instance,
                        const struct inference_request *request);
int inference_model_close(struct inference_model_instance *instance);
const char *inference_status_name(int status);

#endif
