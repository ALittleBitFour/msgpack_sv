// Class: msgpack_enc
class msgpack_enc extends uvm_object;
    //Variable: buffer
    byte unsigned buffer[$];

    extern function new(string name = "msgpack_enc");

    extern function void write_nil();
    extern function void write_bool(bit value);
    extern function void write_int(longint value);
    extern function void write_uint(longint unsigned value);
    extern function void write_real(real value);
    extern function void write_shortreal(shortreal value);
    extern function void write_string(string value);

    extern protected function void write(byte unsigned symbol);
    extern protected function void write_and_shift(longint unsigned value, byte unsigned valid_byte);

    `uvm_object_utils(msgpack_enc)
endclass

function msgpack_enc::new(string name = "msgpack_enc");
    super.new(name);
endfunction

function void msgpack_enc::write(byte unsigned symbol);
    buffer.push_back(symbol);
endfunction

function void msgpack_enc::write_and_shift(longint unsigned value, byte unsigned valid_byte);
    for(byte unsigned i = 0; i < valid_byte; i++) begin
        buffer.push_back(value >> ((valid_byte - 1) - i)*8);
    end
endfunction

function void msgpack_enc::write_nil();
    write(MPACK_NIL);
endfunction

function void msgpack_enc::write_bool(bit value);
    if(value) write(MPACK_TRUE);
    else write(MPACK_FALSE);
endfunction

function void msgpack_enc::write_int(longint value);
    if(value >= 0) begin
        write_uint(value);
    end
    else if(value >= -32) begin
        write(MPACK_NEGATIVE_FIXINT | value);
    end
    else if(value >= -128) begin
        write(MPACK_INT8);
        write(value);
    end
    else if(value >= -32768) begin
        write(MPACK_INT16);
        write_and_shift(value, 2);
    end
    else if(value >= (-2147483647 - 1)) begin
        write(MPACK_INT32);
        write_and_shift(value, 4);
    end
    else begin
        write(MPACK_INT64);
        write_and_shift(value, 8);
    end
endfunction

function void msgpack_enc::write_uint(longint unsigned value);
    if(value <= 7'h7f) begin
        write(MPACK_POSITIVE_FIXINT | value);
    end
    else if(value <= 8'hff) begin
        write(MPACK_UINT8);
        write(value);
    end
    else if(value <= 16'hffff) begin
        write(MPACK_UINT16);
        write_and_shift(value, 2);
    end
    else if(value <= 32'hffff_ffff) begin
        write(MPACK_UINT32);
        write_and_shift(value, 4);
    end
    else begin
        write(MPACK_UINT64);
        write_and_shift(value, 8);
    end
endfunction

function void msgpack_enc::write_real(real value);
    write(MPACK_FLOAT64);
    write_and_shift($realtobits(value), 8);
endfunction

function void msgpack_enc::write_shortreal(shortreal value);
    write(MPACK_FLOAT32);
    write_and_shift($shortrealtobits(value), 4);
endfunction

function void msgpack_enc::write_string(string value);
    int unsigned str_size = value.len();
    if(str_size < 32) begin
        write(MPACK_FIXSTR | str_size);
    end
    else if(str_size <= 32'h0000_00ff) begin
        write(MPACK_STR8);
        write(str_size);
    end
    else if(str_size <= 32'h0000_ffff) begin
        write(MPACK_STR16 | str_size);
        write_and_shift(str_size, 2);
    end
    else if(str_size <= 32'hffff_ffff) begin
        write(MPACK_STR32);
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