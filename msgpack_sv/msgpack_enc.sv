// Class: msgpack_enc
class msgpack_enc extends uvm_object;
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    protected mpack_buffer buffer[$];
    protected mpack_uint32 current_buffer;
    protected longint current_elem_size[$];
    `else
    protected mpack_buffer buffer;
    `endif

    extern function new(string name = "msgpack_enc");

    extern function mpack_buffer get_buffer();

    extern function void write_nil();
    extern function void write_bool(bit value);
    extern function void write_int(longint value);
    extern function void write_uint(longint unsigned value);
    extern function void write_real(real value);
    extern function void write_shortreal(shortreal value);
    extern function void write_string(string value);
    extern function void write_bin(byte unsigned value[]);
    extern function void write_array(int unsigned size);
    
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    extern function void write_array_begin();
    extern function void write_array_end();
    `endif

    extern protected function void write(byte unsigned symbol);
    extern protected function void write_type(byte unsigned symbol);
    extern protected function void write_and_shift(longint unsigned value, byte unsigned valid_byte);

    `uvm_object_utils(msgpack_enc)
endclass

function msgpack_enc::new(string name = "msgpack_enc");
    super.new(name);
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    buffer.push_back({});
    current_buffer = 0;
    current_elem_size.push_back(0);
    `endif
endfunction

function mpack_buffer msgpack_enc::get_buffer();
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    return buffer[0];
    `else
    return buffer;
    `endif
endfunction

function void msgpack_enc::write(byte unsigned symbol);
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    buffer[current_buffer].push_back(symbol);
    `else
    buffer.push_back(symbol);
    `endif
endfunction

function void msgpack_enc::write_type(byte unsigned symbol);
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    buffer[current_buffer].push_back(symbol);
    current_elem_size[current_buffer]++;
    `else
    buffer.push_back(symbol);
    `endif
endfunction

function void msgpack_enc::write_and_shift(longint unsigned value, byte unsigned valid_byte);
    for(byte unsigned i = 0; i < valid_byte; i++) begin
        `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
        buffer[current_buffer].push_back(value >> ((valid_byte - 1) - i)*8);
        `else
        buffer.push_back(value >> ((valid_byte - 1) - i)*8);
        `endif
    end
endfunction

function void msgpack_enc::write_nil();
    write_type(MPACK_NIL);
endfunction

function void msgpack_enc::write_bool(bit value);
    if(value) write_type(MPACK_TRUE);
    else write_type(MPACK_FALSE);
endfunction

function void msgpack_enc::write_int(longint value);
    if(value >= 0) begin
        write_uint(value);
    end
    else if(value >= -32) begin
        write_type(MPACK_NEGATIVE_FIXINT | value);
    end
    else if(value >= -128) begin
        write_type(MPACK_INT8);
        write(value);
    end
    else if(value >= -32768) begin
        write_type(MPACK_INT16);
        write_and_shift(value, 2);
    end
    else if(value >= (-2147483647 - 1)) begin
        write_type(MPACK_INT32);
        write_and_shift(value, 4);
    end
    else begin
        write_type(MPACK_INT64);
        write_and_shift(value, 8);
    end
endfunction

function void msgpack_enc::write_uint(longint unsigned value);
    if(value <= 7'h7f) begin
        write_type(MPACK_POSITIVE_FIXINT | value);
    end
    else if(value <= 8'hff) begin
        write_type(MPACK_UINT8);
        write(value);
    end
    else if(value <= 16'hffff) begin
        write_type(MPACK_UINT16);
        write_and_shift(value, 2);
    end
    else if(value <= 32'hffff_ffff) begin
        write_type(MPACK_UINT32);
        write_and_shift(value, 4);
    end
    else begin
        write_type(MPACK_UINT64);
        write_and_shift(value, 8);
    end
endfunction

function void msgpack_enc::write_real(real value);
    write_type(MPACK_FLOAT64);
    write_and_shift($realtobits(value), 8);
endfunction

function void msgpack_enc::write_shortreal(shortreal value);
    write(MPACK_FLOAT32);
    write_and_shift($shortrealtobits(value), 4);
endfunction

function void msgpack_enc::write_string(string value);
    int unsigned str_size = value.len();
    if(str_size < 32) begin
        write_type(MPACK_FIXSTR | str_size);
    end
    else if(str_size <= 32'h0000_00ff) begin
        write_type(MPACK_STR8);
        write(str_size);
    end
    else if(str_size <= 32'h0000_ffff) begin
        write_type(MPACK_STR16);
        write_and_shift(str_size, 2);
    end
    else if(str_size <= 32'hffff_ffff) begin
        write_type(MPACK_STR32);
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
        write_type(MPACK_BIN8);
        write(bin_size);
    end
    else if(bin_size <= 32'h0000_ffff) begin
        write_type(MPACK_BIN16);
        write_and_shift(bin_size, 2);
    end
    else if(bin_size <= 32'hffff_ffff) begin
        write_type(MPACK_BIN32);
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

function void msgpack_enc::write_array(int unsigned size);
    if(size <= 15) begin
        write_type(MPACK_FIXARRAY | size);
    end 
    else if(size <= 32'h0000_ffff) begin
        write_type(MPACK_ARRAY16);
        write_and_shift(size, 2);
    end 
    else if(size <= 32'hffff_ffff) begin
        write_type(MPACK_ARRAY32);
        write_and_shift(size, 4);
    end
    else begin
        `uvm_fatal(get_name(), "Array is bigger than (2^32)-1 bytes")
        return;
    end
    `ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
    current_elem_size[current_buffer] -= size;
    `endif
endfunction

`ifndef MPACK_DISABLE_DYN_ARRAY_SIZE_CALC
function void msgpack_enc::write_array_begin();
    buffer.push_back({});
    current_elem_size[current_buffer]++;
    current_elem_size.push_back(0);
    current_buffer++;
endfunction

function void msgpack_enc::write_array_end();
    longint elem_size = current_elem_size.pop_back();
    current_buffer--;
    write_array(elem_size);
    buffer[current_buffer] = {buffer[current_buffer], buffer.pop_back()};
    current_elem_size[current_buffer] += elem_size; // hack, fix it later
endfunction
`endif