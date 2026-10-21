package ai_types_pkg;
    typedef enum logic [2:0] {
        TENSOR_FREE,
        TENSOR_WRITING,
        TENSOR_READY,
        TENSOR_RUNNING,
        TENSOR_ERROR
    } tensor_slot_state_t;

    typedef struct packed {
        logic [31:0] addr;
        logic [31:0] frame_id;
        logic [63:0] timestamp;
        logic [31:0] version;
        logic [31:0] bytes;
        tensor_slot_state_t state;
        logic [7:0] error;
    } tensor_slot_meta_t;

    typedef struct packed {
        logic [3:0]  stream;
        logic [3:0]  count;
        logic [511:0] boxes;
        logic [1023:0] labels;
    } overlay_command_t;
endpackage
