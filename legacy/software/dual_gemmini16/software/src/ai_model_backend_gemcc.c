#include "ai_model_backend.h"

#include <string.h>

#include "platform.h"
#include "mmio.h"
#include "console.h"

/* The generated GemCC runtime is intentionally kept behind this adapter. */
#include "../gemcc_runtime/engine/gemcc_model.h"
#include "../gemcc_runtime/engine/gemcc_trace.h"

#define GEMCC_WORKSPACE_BYTES 31800256U
#define GEMCC_OUTPUT_BYTES (84U * 6300U * 4U)
#define GEMCC_MODEL_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(5))

static GemccModelInstance model;
static GemccModelDescriptor descriptor;
static unsigned char workspace[GEMCC_WORKSPACE_BYTES] __attribute__((aligned(64)));
static unsigned char output[GEMCC_OUTPUT_BYTES] __attribute__((aligned(64)));
static unsigned running;
static AiModelFrameRequest request;
static unsigned initialized;
static volatile uint32_t stage;
static volatile uint64_t stage_start_cycle;
static unsigned debug_reported;
static uint32_t trace_kinds[128];
static uint32_t trace_next_op;

enum {
    GEMCC_STAGE_IDLE = 0,
    GEMCC_STAGE_SUBMITTED = 1,
    GEMCC_STAGE_FORWARD = 2,
    GEMCC_STAGE_COMPLETE = 3,
    GEMCC_STAGE_ERROR = 4
};

/* The generated forward is synchronous.  These UART breadcrumbs are emitted
 * from the ABI wrappers so the last line survives even when a RoCC call does
 * not return to the runtime polling loop. */
void gemcc_trace_reset(void)
{
    memset(trace_kinds, 0, sizeof(trace_kinds));
    trace_next_op = 0U;
}

uint32_t gemcc_trace_begin(uint32_t kind, uint32_t x0, uint32_t x1,
                           uint32_t x2, uint32_t x3, uint32_t x4,
                           uint32_t x5)
{
    uint32_t op = trace_next_op++;
    if (op < (uint32_t)(sizeof(trace_kinds) / sizeof(trace_kinds[0])))
        trace_kinds[op] = kind;
    console_puts("AI LAYER ");
    console_put_u32(op);
    console_putc(' ');
    console_puts(kind == GEMCC_TRACE_KIND_CONV ? "CONV" : "MATMUL");
    console_puts(" BEGIN ");
    if (kind == GEMCC_TRACE_KIND_CONV) {
        console_puts("ih=");
        console_put_u32(x0);
        console_puts(" iw=");
        console_put_u32(x1);
        console_puts(" ic=");
        console_put_u32(x2);
        console_puts(" oh=");
        console_put_u32(x3);
        console_puts(" ow=");
        console_put_u32(x4);
        console_puts(" oc=");
        console_put_u32(x5);
    } else {
        console_puts("I=");
        console_put_u32(x0);
        console_puts(" J=");
        console_put_u32(x1);
        console_puts(" K=");
        console_put_u32(x2);
    }
    console_puts("\r\n");
    return op;
}

void gemcc_trace_phase(uint32_t op, uint32_t phase)
{
    console_puts("AI LAYER ");
    console_put_u32(op);
    console_putc(' ');
    if (op < (uint32_t)(sizeof(trace_kinds) / sizeof(trace_kinds[0])))
        console_puts(trace_kinds[op] == GEMCC_TRACE_KIND_CONV ? "CONV" :
                     "MATMUL");
    else
        console_puts("OP");
    console_putc(' ');
    if (phase == GEMCC_TRACE_PHASE_LAUNCH)
        console_puts("LAUNCH");
    else if (phase == GEMCC_TRACE_PHASE_GEMMINI_DONE)
        console_puts("GEMMINI_DONE");
    else if (phase == GEMCC_TRACE_PHASE_DONE)
        console_puts("DONE");
    else
        console_puts("PHASE");
    console_puts("\r\n");
}

void ai_model_backend_init(void)
{
    gemcc_model_instance_init(&model);
    initialized = 0U;
    running = 0U;
    stage = GEMCC_STAGE_IDLE;
    debug_reported = 0U;
    if (gemcc_model_descriptor(&descriptor) != GEMCC_OK)
        return;
    if (gemcc_model_create(&model, &descriptor, &(GemccLoadConfig){
            .hardware_profile_id = "xcvu13p-dim16-packed-quicktest",
            .quant_mode = "int8",
            .quant_profile_version = "0",
            .model_hash = "ee82cf0a12081810b04a77f7556b00f92a62d48319a949fa392701ec9a9eb6a6"
        }) != GEMCC_OK)
        return;
    if (gemcc_model_bind_workspace(&model, workspace, sizeof(workspace)) != GEMCC_OK)
        return;
    if (gemcc_model_init_instance(&model, gemcc_library_device_hooks()) != GEMCC_OK)
        return;
    initialized = 1U;
    console_puts("AI MODEL init OK (YOLOv5n DIM16)\r\n");
}

int ai_model_backend_submit(const AiModelFrameRequest *input)
{
    if (!initialized || running || !input || input->worker_id != 0U ||
        input->input_addr == 0U || input->input_bytes != AI_YOLOV5NU_INPUT_WIDTH *
        AI_YOLOV5NU_INPUT_HEIGHT * 3U)
        return -1;
    request = *input;
    running = 1U;
    stage = GEMCC_STAGE_SUBMITTED;
    stage_start_cycle = read_cycle();
    return 0;
}

int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion)
{
    GemccRunRequest run;
    int status;
    if (!initialized || !running || worker_id != 0U || !completion)
        return -1;
    memset(&run, 0, sizeof(run));
    /* Framebuffer reports physical DDR addresses; Rocket reaches the same
     * storage through the bit-31 CPU alias used by the DDR bridge. */
    run.input = (const void *)AI_DDR_CPU_ALIAS(request.input_addr);
    run.input_bytes = request.input_bytes;
    run.output = output;
    run.output_bytes = sizeof(output);
    run.dtype = GEMCC_DTYPE_I8;
    /* The generated model ABI is NCHW [1,3,480,640]. */
    run.layout = GEMCC_LAYOUT_NCHW;
    run.rank = 4;
    run.shape[0] = 1;
    run.shape[1] = 3;
    run.shape[2] = 480;
    run.shape[3] = 640;
    stage = GEMCC_STAGE_FORWARD;
    if (debug_reported == 0U) {
        console_puts("AI MODEL_FORWARD_BEGIN stream=");
        console_put_u32(request.stream_id + 1U);
        console_puts(" frame=");
        console_put_hex64(request.frame_id);
        console_puts(" input=");
        console_put_hex32((uint32_t)(uintptr_t)run.input);
        console_puts("\r\n");
        debug_reported = 1U;
    }
    gemcc_trace_reset();
    status = gemcc_model_run(&model, &run, 0);
    running = 0U;
    if (read_cycle() - stage_start_cycle > GEMCC_MODEL_TIMEOUT_CYCLES) {
        stage = GEMCC_STAGE_ERROR;
        return -2;
    }
    if (status != GEMCC_OK) {
        stage = GEMCC_STAGE_ERROR;
        console_puts("AI MODEL_FORWARD_ERROR=");
        console_put_u32((uint32_t)status);
        console_puts("\r\n");
        return status;
    }
    stage = GEMCC_STAGE_COMPLETE;
    console_puts("AI MODEL_FORWARD_DONE cycles=");
    console_put_u32((uint32_t)(read_cycle() - stage_start_cycle));
    console_puts("\r\n");
    memset(completion, 0, sizeof(*completion));
    completion->job_id = request.job_id;
    completion->worker_id = 0U;
    completion->stream_id = request.stream_id;
    completion->frame_id = request.frame_id;
    completion->version = request.version;
    completion->status = 0;
    completion->output_addr = (uintptr_t)output;
    completion->output_desc.dtype = AI_TENSOR_DTYPE_F32;
    completion->output_desc.layout = AI_TENSOR_LAYOUT_CHANNEL_ANCHOR;
    completion->output_desc.channels = 84U;
    completion->output_desc.anchors = 6300U;
    completion->output_desc.bytes = sizeof(output);
    return 1;
}

int ai_model_backend_abort(uint32_t worker_id)
{
    if (worker_id != 0U)
        return -1;
    running = 0U;
    stage = GEMCC_STAGE_IDLE;
    return 0;
}

uint32_t ai_model_backend_stage(void)
{
    return stage;
}

uint64_t ai_model_backend_elapsed_cycles(void)
{
    return stage == GEMCC_STAGE_IDLE ? 0U : read_cycle() - stage_start_cycle;
}

void ai_model_backend_get_pe_stats(AiModelPeStats *stats)
{
    if (stats != 0)
        memset(stats, 0, sizeof(*stats));
}
