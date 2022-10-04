typedef enum byte unsigned {
    MPACK_POSITIVE_FIXINT = 8'h00,
    MPACK_FIXMAP          = 8'h80,
    MPACK_FIXARRAY        = 8'h90,
    MPACK_FIXSTR          = 8'hA0,
    MPACK_NIL             = 8'hc0,
    MPACK_FALSE           = 8'hc2,
    MPACK_TRUE            = 8'hc3,
    MPACK_BIN8            = 8'hc4,
    MPACK_BIN16           = 8'hc5,
    MPACK_BIN32           = 8'hc6,
    MPACK_EXT8            = 8'hc7,
    MPACK_EXT16           = 8'hc8,
    MPACK_EXT32           = 8'hc9,
    MPACK_FLOAT32         = 8'hca,
    MPACK_FLOAT64         = 8'hcb,
    MPACK_UINT8           = 8'hcc,
    MPACK_UINT16          = 8'hcd,
    MPACK_UINT32          = 8'hce,
    MPACK_UINT64          = 8'hcf,
    MPACK_INT8            = 8'hd0,
    MPACK_INT16           = 8'hd1,
    MPACK_INT32           = 8'hd2,
    MPACK_INT64           = 8'hd3,
    MPACK_FIXEXT1         = 8'hd4,
    MPACK_FIXEXT2         = 8'hd5,
    MPACK_FIXEXT4         = 8'hd6,
    MPACK_FIXEXT8         = 8'hd7,
    MPACK_FIXEXT16        = 8'hd8,
    MPACK_STR8            = 8'hd9,
    MPACK_STR16           = 8'hda,
    MPACK_STR32           = 8'hdb,
    MPACK_ARRAY16         = 8'hdc,
    MPACK_ARRAY32         = 8'hdd,
    MPACK_MAP16           = 8'hde,
    MPACK_MAP32           = 8'hdf,
    MPACK_NEGATIVE_FIXINT = 8'he0
} msgpack_formats_t;

typedef enum int {
    MPACK_OK,
    MPACK_OOB,
    MPACK_WRONG_TYPE
} msgpack_result_t;

typedef int unsigned mpack_uint32;
typedef longint unsigned mpack_uint64;
typedef byte unsigned mpack_buffer[$];