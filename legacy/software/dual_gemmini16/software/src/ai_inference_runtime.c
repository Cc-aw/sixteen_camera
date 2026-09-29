#include "ai_inference_runtime.h"

static int is_aligned(const void *pointer, size_t alignment)
{
    return pointer != 0 && alignment != 0 &&
           ((uintptr_t)pointer % alignment) == 0;
}

static int validate_desc(const struct inference_tensor_desc *desc)
{
    return desc != 0 && desc->rank != 0 && desc->rank <= 4 &&
           desc->bytes != 0 && desc->alignment != 0 &&
           (desc->alignment & (desc->alignment - 1)) == 0;
}

int inference_model_open(
    struct inference_model_instance *instance,
    const struct inference_model_descriptor *descriptor,
    const struct inference_device_context *device)
{
    if (instance == 0 || descriptor == 0 || device == 0 ||
        descriptor->execute == 0 || descriptor->name == 0)
        return INFERENCE_ERR_ARGUMENT;
    if (descriptor->abi_version != 1)
        return INFERENCE_ERR_ABI;
    if (descriptor->hardware_profile != device->hardware_profile)
        return INFERENCE_ERR_PROFILE;
    if (!validate_desc(&descriptor->input) || !validate_desc(&descriptor->output))
        return INFERENCE_ERR_ARGUMENT;

    instance->descriptor = descriptor;
    instance->device = device;
    instance->opened = 1;
    return INFERENCE_OK;
}

int inference_model_run(struct inference_model_instance *instance,
                        const struct inference_request *request)
{
    const struct inference_tensor_desc *input_desc;
    const struct inference_tensor_desc *output_desc;

    if (instance == 0 || request == 0 || instance->opened == 0 ||
        instance->descriptor == 0 || instance->device == 0)
        return INFERENCE_ERR_STATE;
    if (request->input == 0 || request->output == 0 ||
        request->input->data == 0 || request->output->data == 0 ||
        request->input_name == 0)
        return INFERENCE_ERR_ARGUMENT;

    input_desc = &instance->descriptor->input;
    output_desc = &instance->descriptor->output;
    if (request->input->bytes < input_desc->bytes ||
        !is_aligned(request->input->data, input_desc->alignment))
        return INFERENCE_ERR_INPUT;
    if (request->output->bytes < output_desc->bytes ||
        !is_aligned(request->output->data, output_desc->alignment))
        return INFERENCE_ERR_OUTPUT;

    return instance->descriptor->execute(instance, request) == 0 ?
           INFERENCE_OK : INFERENCE_ERR_EXECUTE;
}

int inference_model_close(struct inference_model_instance *instance)
{
    if (instance == 0)
        return INFERENCE_ERR_ARGUMENT;
    instance->descriptor = 0;
    instance->device = 0;
    instance->opened = 0;
    return INFERENCE_OK;
}

const char *inference_status_name(int status)
{
    switch (status) {
    case INFERENCE_OK: return "ok";
    case INFERENCE_ERR_ARGUMENT: return "argument";
    case INFERENCE_ERR_ABI: return "abi";
    case INFERENCE_ERR_PROFILE: return "profile";
    case INFERENCE_ERR_INPUT: return "input";
    case INFERENCE_ERR_OUTPUT: return "output";
    case INFERENCE_ERR_STATE: return "state";
    case INFERENCE_ERR_EXECUTE: return "execute";
    default: return "unknown";
    }
}
