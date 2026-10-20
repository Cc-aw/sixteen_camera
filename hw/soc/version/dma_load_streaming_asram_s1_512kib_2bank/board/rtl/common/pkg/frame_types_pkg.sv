package frame_types_pkg;
    typedef enum logic [1:0] {
        FRAME_FREE,
        FRAME_WRITING,
        FRAME_READY,
        FRAME_READING
    } frame_state_t;

    typedef struct packed {
        logic [31:0] addr;
        logic [31:0] frame_id;
        logic [31:0] source_frame_id;
        logic [63:0] timestamp;
        logic [31:0] version;
        frame_state_t state;
    } frame_meta_t;
endpackage
