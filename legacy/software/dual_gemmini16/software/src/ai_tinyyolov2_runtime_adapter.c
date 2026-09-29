#include "ai_tinyyolov2_runtime_adapter.h"

#include "tinyyolov2_input_contract.h"

#define TINYYOLOV2_RUNTIME_INPUT_BYTES \
    (TINYYOLOV2_INPUT_HEIGHT * TINYYOLOV2_INPUT_WIDTH * \
     TINYYOLOV2_INPUT_CHANNELS)

#define TINYYOLOV2_RUNTIME_PROFILE 0x44313602u

static int tinyyolov2_execute(
    const struct inference_model_instance *instance,
    const struct inference_request *request)
{
    struct tinyyolov2_result *result;
    (void)instance;
    result = (struct tinyyolov2_result *)request->output->data;
    return tinyyolov2_run_detect((const int8_t *)request->input->data,
                                 request->input_name, result) ? 0 : -1;
}

static const struct inference_model_descriptor tinyyolov2_descriptor = {
    .abi_version = 1,
    .hardware_profile = TINYYOLOV2_RUNTIME_PROFILE,
    .name = "TinyYOLOv2-Dual-DIM16",
    .input = {
        .dtype = INFERENCE_DTYPE_I8,
        .layout = INFERENCE_LAYOUT_NHWC,
        .rank = 4,
        .dims = {1, TINYYOLOV2_INPUT_HEIGHT, TINYYOLOV2_INPUT_WIDTH,
                 TINYYOLOV2_INPUT_CHANNELS},
        .bytes = TINYYOLOV2_RUNTIME_INPUT_BYTES,
        .alignment = 64,
    },
    .output = {
        .dtype = INFERENCE_DTYPE_CUSTOM,
        .layout = INFERENCE_LAYOUT_CUSTOM,
        .rank = 1,
        .dims = {sizeof(struct tinyyolov2_result), 0, 0, 0},
        .bytes = sizeof(struct tinyyolov2_result),
        .alignment = sizeof(uint32_t),
    },
    .execute = tinyyolov2_execute,
};

static const struct inference_device_context tinyyolov2_device = {
    .hardware_profile = TINYYOLOV2_RUNTIME_PROFILE,
    .capabilities = 0,
};

static struct inference_model_instance tinyyolov2_instance;
static int tinyyolov2_instance_ready;

int inference_tinyyolov2_open(void)
{
    int status;
    if (tinyyolov2_instance_ready)
        return INFERENCE_OK;
    status = inference_model_open(&tinyyolov2_instance,
                                  &tinyyolov2_descriptor,
                                  &tinyyolov2_device);
    if (status == INFERENCE_OK)
        tinyyolov2_instance_ready = 1;
    return status;
}

int inference_tinyyolov2_run(const int8_t *input, const char *input_name,
                             struct tinyyolov2_result *result)
{
    struct inference_tensor_buffer input_buffer;
    struct inference_tensor_buffer output_buffer;
    struct inference_request request;

    if (input == 0 || input_name == 0 || result == 0)
        return INFERENCE_ERR_ARGUMENT;
    if (!tinyyolov2_instance_ready)
        return INFERENCE_ERR_STATE;

    input_buffer.data = (void *)input;
    input_buffer.bytes = TINYYOLOV2_RUNTIME_INPUT_BYTES;
    input_buffer.alignment = 64;
    output_buffer.data = result;
    output_buffer.bytes = sizeof(*result);
    output_buffer.alignment = sizeof(uint32_t);
    request.input = &input_buffer;
    request.output = &output_buffer;
    request.input_name = input_name;

    return inference_model_run(&tinyyolov2_instance, &request);
}

int inference_tinyyolov2_close(void)
{
    int status;
    if (!tinyyolov2_instance_ready)
        return INFERENCE_OK;
    status = inference_model_close(&tinyyolov2_instance);
    if (status == INFERENCE_OK)
        tinyyolov2_instance_ready = 0;
    return status;
}
