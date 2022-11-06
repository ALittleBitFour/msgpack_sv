/*
Copyright 2022 Ivan Larkou

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is furnished 
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

`ifdef MSGPACK_UVM_SUPPORT
class msgpack_base extends uvm_object;
    `uvm_object_utils(msgpack_base)

    function new(string name = "msgpack_base");
        super.new(name);
    endfunction
endclass

`define msgpack_uvm_object_utils(type_name) `uvm_object_utils(type_name)
`define msgpack_uvm_object_param_utils(type_name) `uvm_object_param_utils(type_name)

`else
 class msgpack_base;
    protected string name;

    function new(string name);
        this.name = name;
    endfunction

    function string get_name();
        return name;
    endfunction
 endclass

`define msgpack_uvm_object_utils(type_name) //dummy_macro
`define msgpack_uvm_object_param_utils(type_name) //dummy_macro
`endif

function void log_error(string name, string error_msg);
`ifdef MSGPACK_UVM_SUPPORT
    `uvm_error(name, error_msg)
`else
    $display("%t: %s: ERROR %s", $time(), name, error_msg);
`endif
endfunction

function void log_fatal(string name, string fatal_msg);
`ifdef MSGPACK_UVM_SUPPORT
    `uvm_fatal(name, fatal_msg)
`else
    $display("%t: %s: FATAL ERROR %s", $time(), name, fatal_msg);
    $finish();
`endif
endfunction

function void log(string name, string msg);
`ifdef MSGPACK_UVM_SUPPORT
    `uvm_info(name, msg, UVM_DEBUG)
`else
    $display("%t: %s: %s", $time(), name, msg);
`endif
endfunction

typedef enum byte unsigned {
    MSGPACK_POSITIVE_FIXINT = 8'h00,
    MSGPACK_FIXMAP          = 8'h80,
    MSGPACK_FIXARRAY        = 8'h90,
    MSGPACK_FIXSTR          = 8'hA0,
    MSGPACK_NIL             = 8'hc0,
    MSGPACK_FALSE           = 8'hc2,
    MSGPACK_TRUE            = 8'hc3,
    MSGPACK_BIN8            = 8'hc4,
    MSGPACK_BIN16           = 8'hc5,
    MSGPACK_BIN32           = 8'hc6,
    MSGPACK_EXT8            = 8'hc7,
    MSGPACK_EXT16           = 8'hc8,
    MSGPACK_EXT32           = 8'hc9,
    MSGPACK_FLOAT32         = 8'hca,
    MSGPACK_FLOAT64         = 8'hcb,
    MSGPACK_UINT8           = 8'hcc,
    MSGPACK_UINT16          = 8'hcd,
    MSGPACK_UINT32          = 8'hce,
    MSGPACK_UINT64          = 8'hcf,
    MSGPACK_INT8            = 8'hd0,
    MSGPACK_INT16           = 8'hd1,
    MSGPACK_INT32           = 8'hd2,
    MSGPACK_INT64           = 8'hd3,
    MSGPACK_FIXEXT1         = 8'hd4,
    MSGPACK_FIXEXT2         = 8'hd5,
    MSGPACK_FIXEXT4         = 8'hd6,
    MSGPACK_FIXEXT8         = 8'hd7,
    MSGPACK_FIXEXT16        = 8'hd8,
    MSGPACK_STR8            = 8'hd9,
    MSGPACK_STR16           = 8'hda,
    MSGPACK_STR32           = 8'hdb,
    MSGPACK_ARRAY16         = 8'hdc,
    MSGPACK_ARRAY32         = 8'hdd,
    MSGPACK_MAP16           = 8'hde,
    MSGPACK_MAP32           = 8'hdf,
    MSGPACK_NEGATIVE_FIXINT = 8'he0
} msgpack_formats_t;

typedef enum {
    MSGPACK_NODE_INT,
    MSGPACK_NODE_UINT,
    MSGPACK_NODE_REAL,
    MSGPACK_NODE_SHORTREAL,
    MSGPACK_NODE_STRING,
    MSGPACK_NODE_BOOL,
    MSGPACK_NODE_ARRAY,
    MSGPACK_NODE_MAP,
    MSGPACK_NODE_BIN,
    MSGPACK_NODE_EXT
} msgpack_node_t;

typedef enum int {
    MSGPACK_OK,
    MSGPACK_OOB,
    MSGPACK_WRONG_TYPE
} msgpack_result_t;

typedef int unsigned msgpack_uint32;
typedef longint unsigned msgpack_uint64;
typedef byte unsigned msgpack_buffer[$];
typedef byte unsigned msgpack_bin[];