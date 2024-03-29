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

`ifndef MSGPACK_DEC__SV
`define MSGPACK_DEC__SV

// Class: msgpack_dec
// This class provides a set of funcitons for read data from a message
//
// Useful links: <msgpack_enc>
class msgpack_dec extends msgpack_base;
    struct {int unsigned offset;} state;

    msgpack_result_t last_result;
    protected msgpack_buffer buffer;

    extern function new(string name = "msgpack_dec");

    // Function: set_buffer
    // Set message to decode
    extern function void set_buffer(msgpack_buffer buffer);

    // Function: read_nil
    extern function void             read_nil();
    // Function: read_bool
    extern function bit              read_bool();
    // Function: read_int
    extern function longint          read_int();
    // Function: read_uint
    extern function longint unsigned read_uint();
    // Function: read_real
    extern function real             read_real();
    // Function: read_shortreal
    extern function shortreal        read_shortreal();
    // Function: read_string
    extern function string           read_string();
    // Function: read_bin
    extern function msgpack_bin      read_bin();
    // Function: read_array
    // Return size of an array
    extern function int unsigned     read_array();
    // Function: read_map
    // Return size of a map
    extern function int unsigned     read_map();

    // Function: peer
    // Peek the next symbol from the message
    extern function bit peek(ref byte unsigned symbol);
    extern protected function byte unsigned    read();
    extern protected function longint unsigned read_and_shift_uint(byte unsigned valid_byte);
    extern protected function longint          read_and_shift_int(byte unsigned valid_byte);

    `msgpack_uvm_object_utils(msgpack_dec)
endclass

function msgpack_dec::new(string name = "msgpack_dec");
    super.new(name);
    state.offset = 0;
endfunction

function void msgpack_dec::set_buffer(msgpack_buffer buffer);
    this.buffer = buffer;
    state.offset = 0;
endfunction

function bit msgpack_dec::peek(ref byte unsigned symbol);
    if(state.offset >= buffer.size()) return 0;
    symbol = buffer[state.offset];
    return 1;
endfunction

function byte unsigned msgpack_dec::read();
    `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
    if(state.offset >= buffer.size()) begin
        last_result = MSGPACK_OOB;
        log_error(get_name(),$sformatf("MsgPack decoding error. Type: %s", last_result.name()));
    end
    `endif
    read = buffer[state.offset];
    state.offset++;
    last_result = MSGPACK_OK;
endfunction

function longint unsigned msgpack_dec::read_and_shift_uint(input byte unsigned valid_byte);
    read_and_shift_uint = 0;
    read_and_shift_uint = MSGPACK_OK;
    repeat(valid_byte) begin
        `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
        if(state.offset >= buffer.size()) begin
            last_result = MSGPACK_OOB;
            log_error(get_name(),$sformatf("MsgPack decoding error. Type: %s", last_result.name()));
        end
        `endif
        read_and_shift_uint = {read_and_shift_uint, buffer[state.offset]};
        state.offset++;
    end
endfunction

function longint msgpack_dec::read_and_shift_int(input byte unsigned valid_byte);
    last_result = MSGPACK_OK;
    read_and_shift_int = 0;
    for(int i = 0; i < valid_byte; i++) begin
        `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
        if(state.offset >= buffer.size()) begin
            last_result = MSGPACK_OOB;
            log_error(get_name(),$sformatf("MsgPack decoding error. Type: %s", last_result.name()));
        end
        `endif
        if(i == 0) begin
            read_and_shift_int = buffer[state.offset] >= 8'h80 ? -1 : 0;
        end
        read_and_shift_int = {read_and_shift_int, buffer[state.offset]};
        state.offset++;
    end
endfunction

function void msgpack_dec::read_nil();
    byte unsigned symbol = read();
    if(last_result == MSGPACK_OK) begin
        if(symbol == MSGPACK_NIL) begin
            last_result = MSGPACK_OK;
        end
        else begin
            last_result = MSGPACK_WRONG_TYPE;
        end
    end   
endfunction

function bit msgpack_dec::read_bool();
    byte unsigned symbol = read();
    if(last_result != MSGPACK_OK) begin
        return read_bool;
    end
    else if(symbol == MSGPACK_FALSE) begin
        read_bool = 1'b0;
        last_result = MSGPACK_OK;
    end
    else if(symbol == MSGPACK_TRUE) begin
        read_bool = 1'b1;
        last_result = MSGPACK_OK;
    end
    else begin
        last_result = MSGPACK_WRONG_TYPE;
    end    
endfunction

function longint unsigned msgpack_dec::read_uint();
    byte unsigned symbol;
    symbol = read();
    if(last_result != MSGPACK_OK) begin
        return 0;
    end
    else if(~symbol & 8'h80) begin
        last_result = MSGPACK_OK;
        return msgpack_uint32'(symbol);
    end
    else if(symbol == MSGPACK_UINT8) begin
        return msgpack_uint32'(read());
    end
    else if(symbol == MSGPACK_UINT16) begin
        return read_and_shift_uint(2);
    end
    else if(symbol == MSGPACK_UINT32) begin
        return read_and_shift_uint(4);
    end
    else if(symbol == MSGPACK_UINT64) begin
        return read_and_shift_uint(8);
    end
    else begin
        read_uint = msgpack_uint32'(symbol);
        last_result = MSGPACK_WRONG_TYPE;
    end    
endfunction

function longint msgpack_dec::read_int();
    byte unsigned symbol;
    longint unsigned uint_value = read_uint();
    if(last_result inside {MSGPACK_OOB, MSGPACK_OK}) begin
        return longint'(uint_value);
    end
    else if((uint_value & 8'he0) == 8'he0) begin
        byte unsigned tmp;
        last_result = MSGPACK_OK;
        tmp = ~(uint_value & 8'hff);
        return 0 - (tmp + 1);
    end
    else if(uint_value == MSGPACK_INT8) begin
        return read_and_shift_int(1);
    end
    else if(uint_value == MSGPACK_INT16) begin
        return read_and_shift_int(2);
    end
    else if(uint_value == MSGPACK_INT32) begin
        return read_and_shift_int(4);
    end
    else if(uint_value == MSGPACK_INT64) begin
        return read_and_shift_int(8);
    end
    else begin
        last_result = MSGPACK_WRONG_TYPE;
    end    
endfunction

function real msgpack_dec::read_real();
    byte unsigned symbol;
    longint unsigned uint_value;
    symbol = read();
    if(last_result != MSGPACK_OK) begin
        return 0;
    end
    if(symbol != MSGPACK_FLOAT64) begin
        last_result = MSGPACK_WRONG_TYPE;
    end
    uint_value = read_and_shift_uint(8);
    return $bitstoreal(uint_value);
endfunction

function shortreal msgpack_dec::read_shortreal();
    byte unsigned symbol;
    longint unsigned uint_value;
    symbol = read();
    if(read_shortreal != MSGPACK_OK) begin
        return 0;
    end
    if(symbol != MSGPACK_FLOAT32) begin
        last_result = MSGPACK_WRONG_TYPE;
    end
    uint_value = read_and_shift_uint(4);
    return $bitstoshortreal(uint_value);
endfunction

function string msgpack_dec::read_string();
    byte unsigned symbol;
    longint unsigned str_size;
    symbol = read();
    if(last_result != MSGPACK_OK) begin
        return "";
    end
    if((symbol & 8'hf0) == MSGPACK_FIXSTR) begin
        str_size = symbol & ~MSGPACK_FIXSTR;
    end
    else if(symbol == MSGPACK_STR8) begin
        str_size = read_and_shift_uint(1);
    end
    else if(symbol == MSGPACK_STR16) begin
        str_size = read_and_shift_uint(2);
    end
    else if(symbol == MSGPACK_STR32) begin
        str_size = read_and_shift_uint(4);
    end
    else begin
        last_result = MSGPACK_WRONG_TYPE;
    end
    for(longint unsigned i = 0; i < str_size; i++) begin
        symbol = read();
        if(last_result != MSGPACK_OK) return "";
        read_string = {read_string, symbol};
    end
endfunction

function msgpack_bin msgpack_dec::read_bin();
    byte unsigned symbol;
    longint unsigned bin_size;
    symbol = read();
    if(last_result != MSGPACK_OK) begin
        return {};
    end
    if(symbol == MSGPACK_BIN8) begin
        bin_size = read_and_shift_uint(1);
    end
    else if(symbol == MSGPACK_BIN16) begin
        bin_size = read_and_shift_uint(2);
    end
    else if(symbol == MSGPACK_BIN32) begin
        bin_size = read_and_shift_uint(4);
    end
    else begin
        last_result = MSGPACK_WRONG_TYPE;
    end
    for(longint unsigned i = 0; i < bin_size; i++) begin
        symbol = read();
        if(last_result != MSGPACK_OK) return {};
        read_bin = {read_bin, symbol};
    end
endfunction

function int unsigned msgpack_dec::read_array();
    byte unsigned symbol;
    longint unsigned uint_size;
    symbol = read();
    if(last_result != MSGPACK_OK) begin
        return 0;
    end
    if((symbol & 8'hf0) == MSGPACK_FIXARRAY) begin
        return symbol & ~MSGPACK_FIXARRAY;
    end
    else if(symbol == MSGPACK_ARRAY16) begin
        uint_size = read_and_shift_uint(2);
        return msgpack_uint32'(uint_size);
    end
    else if(symbol == MSGPACK_ARRAY32) begin
        uint_size = read_and_shift_uint(4);
        return msgpack_uint32'(uint_size);
    end
    else begin
        last_result = MSGPACK_WRONG_TYPE;
    end
endfunction

function int unsigned msgpack_dec::read_map();
    byte unsigned symbol;
    longint unsigned uint_size;
    symbol = read();
    if(last_result != MSGPACK_OK) begin
        return 0;
    end
    if((symbol & 8'hf0) == MSGPACK_FIXMAP) begin
        return symbol & ~MSGPACK_FIXMAP;
    end
    else if(symbol == MSGPACK_MAP16) begin
        uint_size = read_and_shift_uint(2);
        return msgpack_uint32'(uint_size);
    end
    else if(symbol == MSGPACK_MAP32) begin
        uint_size = read_and_shift_uint(4);
        return msgpack_uint32'(uint_size);
    end
    else begin
        last_result = MSGPACK_WRONG_TYPE;
    end
endfunction

`endif