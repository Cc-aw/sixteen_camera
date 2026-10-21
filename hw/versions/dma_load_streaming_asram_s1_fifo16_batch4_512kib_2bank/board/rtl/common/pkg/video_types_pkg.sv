package video_types_pkg;
    typedef struct packed {
        logic [47:0] data;
        logic        sof;
        logic        eol;
    } video_2pixel_beat_t;

    typedef struct packed {
        logic [3:0]  channel;
        logic [31:0] frame_id;
        logic        malformed;
    } video_frame_event_t;
endpackage
