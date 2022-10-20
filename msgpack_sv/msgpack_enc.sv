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

`ifndef MSGPACK_ENC__SV
`define MSGPACK_ENC__SV

// Class: msgpack_enc
// This class provides a set of funcitons for writing data to a message
//
// Useful links: <msgpack_dec>
class msgpack_enc extends uvm_object;
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    protected msgpack_buffer buffer[$];
    protected msgpack_uint32 current_buffer;
    protected longint current_elem_size[$];
    `else
    protected msgpack_buffer buffer;
    `endif

    extern function new(string name = "msgpack_enc");

    // Function: get_buffer
    // Return resulted message
    extern function msgpack_buffer get_buffer();

    // Function: write_nil
    // Write nil value to the message.
    extern function void write_nil();
    // Function: write_bool
    // Write boolean value to the message.
    extern function void write_bool(bit value);
    // Function: write_int
    // Write integer value to the message.
    // A value of an Integer object is limited from -(2^63) upto (2^64)-1
    extern function void write_int(longint value);
    // Function: write_uint
    // Write integer value to the message.
    // A value of an unsigned Integer object is limited from 0 upto (2^64)-1
    extern function void write_uint(longint unsigned value);
    // Function: write_real
    // Write real value to the message.
    // The real data type is the same as a C double(IEEE 754)
    extern function void write_real(real value);
    // Function: write_shortreal
    // Write shortreal value to the message.
    // The shortreal data type is the same as a C float *Not recomended*
    extern function void write_shortreal(shortreal value);
    // Function: write_string
    // Write string value to the message.
    // Maximum byte size of a String object is (2^32)-1
    extern function void write_string(string value);
    // Function: write_bin
    // Write binary value to the message.
    // Maximum length of a Binary object is (2^32)-1
    extern function void write_bin(byte unsigned value[]);
    // Function: write_array
    // Write array to the message.
    // Maximum number of elements of an Array object is (2^32)-1
    //
    // Parameters:
    // size - set number of elements, that will be added to this array
    extern function void write_array(int unsigned size);
    // Function: write_map
    // Write map to the message.
    // Maximum number of elements of an Map object is (2^32)-1
    //
    // Parameters:
    // size - set number of pairs(key,value), that will be added to this map
    extern function void write_map(int unsigned size);
    
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    // Function: write_array_begin
    // Create an array and write all data to the array untill <write_array_end> will be called
    extern function void write_array_begin();
    // Function: write_array_end
    // Finish the array
    extern function void write_array_end();
    // Function: write_map_begin
    // Create a map and write all data to the map untill <write_map_end> will be called
    extern function void write_map_begin();
    // Function: write_map_end
    // Finish the map
    extern function void write_map_end();
    `endif

    extern protected function void write(byte unsigned symbol);
    extern protected function void write_type(byte unsigned symbol);
    extern protected function void write_and_shift(longint unsigned value, byte unsigned valid_byte);
    extern protected function void write_collection(int unsigned size, bit is_map);
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    extern protected function void write_collection_begin();
    extern protected function void write_collection_end(bit is_map);
    `endif

    `uvm_object_utils(msgpack_enc)
endclass

function msgpack_enc::new(string name = "msgpack_enc");
    super.new(name);
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    buffer.push_back({});
    current_buffer = 0;
    current_elem_size.push_back(0);
    `endif
endfunction

function msgpack_buffer msgpack_enc::get_buffer();
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    return buffer[0];
    `else
    return buffer;
    `endif
endfunction

function void msgpack_enc::write(byte unsigned symbol);
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    buffer[current_buffer].push_back(symbol);
    `else
    buffer.push_back(symbol);
    `endif
endfunction

function void msgpack_enc::write_type(byte unsigned symbol);
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    buffer[current_buffer].push_back(symbol);
    current_elem_size[current_buffer]++;
    `else
    buffer.push_back(symbol);
    `endif
endfunction

function void msgpack_enc::write_and_shift(longint unsigned value, byte unsigned valid_byte);
    for(byte unsigned i = 0; i < valid_byte; i++) begin
        `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
        buffer[current_buffer].push_back(value >> ((valid_byte - 1) - i)*8);
        `else
        buffer.push_back(value >> ((valid_byte - 1) - i)*8);
        `endif
    end
endfunction

function void msgpack_enc::write_nil();
    write_type(MSGPACK_NIL);
endfunction

function void msgpack_enc::write_bool(bit value);
    if(value) write_type(MSGPACK_TRUE);
    else write_type(MSGPACK_FALSE);
endfunction

function void msgpack_enc::write_int(longint value);
    if(value >= 0) begin
        write_uint(value);
    end
    else if(value >= -32) begin
        write_type(MSGPACK_NEGATIVE_FIXINT | value);
    end
    else if(value >= -128) begin
        write_type(MSGPACK_INT8);
        write(value);
    end
    else if(value >= -32768) begin
        write_type(MSGPACK_INT16);
        write_and_shift(value, 2);
    end
    else if(value >= (-2147483647 - 1)) begin
        write_type(MSGPACK_INT32);
        write_and_shift(value, 4);
    end
    else begin
        write_type(MSGPACK_INT64);
        write_and_shift(value, 8);
    end
endfunction

function void msgpack_enc::write_uint(longint unsigned value);
    if(value <= 7'h7f) begin
        write_type(MSGPACK_POSITIVE_FIXINT | value);
    end
    else if(value <= 8'hff) begin
        write_type(MSGPACK_UINT8);
        write(value);
    end
    else if(value <= 16'hffff) begin
        write_type(MSGPACK_UINT16);
        write_and_shift(value, 2);
    end
    else if(value <= 32'hffff_ffff) begin
        write_type(MSGPACK_UINT32);
        write_and_shift(value, 4);
    end
    else begin
        write_type(MSGPACK_UINT64);
        write_and_shift(value, 8);
    end
endfunction

function void msgpack_enc::write_real(real value);
    write_type(MSGPACK_FLOAT64);
    write_and_shift($realtobits(value), 8);
endfunction

function void msgpack_enc::write_shortreal(shortreal value);
    write(MSGPACK_FLOAT32);
    write_and_shift($shortrealtobits(value), 4);
endfunction

function void msgpack_enc::write_string(string value);
    int unsigned str_size = value.len();
    if(str_size < 32) begin
        write_type(MSGPACK_FIXSTR | str_size);
    end
    else if(str_size <= 32'h0000_00ff) begin
        write_type(MSGPACK_STR8);
        write(str_size);
    end
    else if(str_size <= 32'h0000_ffff) begin
        write_type(MSGPACK_STR16);
        write_and_shift(str_size, 2);
    end
    else if(str_size <= 32'hffff_ffff) begin
        write_type(MSGPACK_STR32);
        write_and_shift(str_size, 4);
    end
    else begin
        `uvm_fatal(get_name(), "Realy?! String is bigger than (2^32)-1 bytes")
        return;
    end
    foreach(value[i]) begin
        write(value[i]);
    end
endfunction

function void msgpack_enc::write_bin(byte unsigned value[]);
    int unsigned bin_size = $size(value);
    if(bin_size <= 32'h0000_00ff) begin
        write_type(MSGPACK_BIN8);
        write(bin_size);
    end
    else if(bin_size <= 32'h0000_ffff) begin
        write_type(MSGPACK_BIN16);
        write_and_shift(bin_size, 2);
    end
    else if(bin_size <= 32'hffff_ffff) begin
        write_type(MSGPACK_BIN32);
        write_and_shift(bin_size, 4);
    end
    else begin
        `uvm_fatal(get_name(), "Binary data is bigger than (2^32)-1 bytes")
        return;
    end
    foreach(value[i]) begin
        write(value[i]);
    end
endfunction

function void msgpack_enc::write_collection(int unsigned size, bit is_map);
    `ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    current_elem_size[current_buffer] -= size << is_map;
    `endif
    if(size <= 15) begin
        write_type((MSGPACK_FIXARRAY | size) & ~(is_map << 4));
    end 
    else if(size <= 32'h0000_ffff) begin
        write_type(MSGPACK_ARRAY16 | is_map << 1);
        write_and_shift(size, 2);
    end 
    else if(size <= 32'hffff_ffff) begin
        write_type(MSGPACK_ARRAY32 | is_map << 1);
        write_and_shift(size, 4);
    end
    else begin
        `uvm_fatal(get_name(), "Array is bigger than (2^32)-1 bytes")
        return;
    end
endfunction

function void msgpack_enc::write_array(int unsigned size);
    write_collection(size, 0);
endfunction

function void msgpack_enc::write_map(int unsigned size);
    write_collection(size, 1);
endfunction

`ifndef MSGPACK_DISABLE_DYN_ARRAY_SIZE_CALC
function void msgpack_enc::write_collection_begin();
    buffer.push_back({});
    current_elem_size[current_buffer]++;
    current_elem_size.push_back(0);
    current_buffer++;
endfunction

function void msgpack_enc::write_collection_end(bit is_map);
    longint elem_size = current_elem_size.pop_back();
    current_buffer--;
    write_collection(elem_size, is_map);
    buffer[current_buffer] = {buffer[current_buffer], buffer.pop_back()};
    current_elem_size[current_buffer] += elem_size; // hack, fix it later
endfunction

function void msgpack_enc::write_array_begin();
    write_collection_begin();
endfunction

function void msgpack_enc::write_array_end();
    write_collection_end(0);
endfunction

function void msgpack_enc::write_map_begin();
    write_collection_begin();
endfunction

function void msgpack_enc::write_map_end();
    current_elem_size[current_buffer] >>= 1;
    write_collection_end(1);
endfunction

`endif

`endif