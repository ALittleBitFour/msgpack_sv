class msgpack_dec extends uvm_object;
    struct {int unsigned offset;} state;

    protected byte unsigned buffer[$];

    extern function new(string name = "msgpack_dec");

    extern function void set_buffer(byte unsigned buffer[$]);

    extern function msgpack_result_t read_nil();
    extern function msgpack_result_t read_bool(ref bit value);
    extern function msgpack_result_t read_int(ref longint value);
    extern function msgpack_result_t read_uint(ref longint unsigned value);
    extern function msgpack_result_t read_real(ref real value);
    extern function msgpack_result_t read_shortreal(ref shortreal value);
    extern function msgpack_result_t read_string(ref string value);

    extern protected function msgpack_result_t read(ref byte unsigned value);
    extern protected function msgpack_result_t read_and_shift_uint(ref longint unsigned value, 
                                                                   input byte unsigned valid_byte);
    extern protected function msgpack_result_t read_and_shift_int(ref longint value, 
                                                                  input byte unsigned valid_byte);

    `uvm_object_utils(msgpack_dec)
endclass

function msgpack_dec::new(string name = "msgpack_dec");
    super.new(name);
    state.offset = 0;
endfunction

function void msgpack_dec::set_buffer(byte unsigned buffer[$]);
    this.buffer = buffer;
endfunction

function msgpack_result_t msgpack_dec::read(ref byte unsigned value);
    `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
    if(state.offset >= buffer.size()) begin
        `uvm_error(get_name(), "Out of bound access");
        return MPACK_OOB;
    end
    `endif
    value = buffer[state.offset];
    state.offset++;
    return MPACK_OK;
endfunction

function msgpack_result_t msgpack_dec::read_and_shift_uint(ref longint unsigned value, input byte unsigned valid_byte);
    value = 0;
    read_and_shift_uint = MPACK_OK;
    repeat(valid_byte) begin
        `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
        if(state.offset >= buffer.size()) begin
            `uvm_error(get_name(), "Out of bound access");
            return MPACK_OOB;
        end
        `endif
        value = {value, buffer[state.offset]};
        state.offset++;
    end
endfunction

function msgpack_result_t msgpack_dec::read_and_shift_int(ref longint value, input byte unsigned valid_byte);
    read_and_shift_int = MPACK_OK;
    value = 0;
    for(int i = 0; i < valid_byte; i++) begin
        `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
        if(state.offset >= buffer.size()) begin
            `uvm_error(get_name(), "Out of bound access");
            return MPACK_OOB;
        end
        `endif
        if(i == 0) begin
            value = buffer[state.offset] >= 8'h80 ? -1 : 0;
        end
        value = {value, buffer[state.offset]};
        state.offset++;
    end
endfunction

function msgpack_result_t msgpack_dec::read_nil();
    byte unsigned symbol;
    read_nil = read(symbol);
    if(read_nil == MPACK_OK) begin
        if(symbol == MPACK_NIL) begin
            return MPACK_OK;
        end
        else begin
            return MPACK_WRONG_TYPE;
        end
    end   
endfunction

function msgpack_result_t msgpack_dec::read_bool(ref bit value);
    byte unsigned symbol;
    read_bool = read(symbol);
    if(read_bool != MPACK_OK) begin
        return read_bool;
    end
    else if(symbol == MPACK_FALSE) begin
        value = 1'b0;
        return MPACK_OK;
    end
    else if(symbol == MPACK_TRUE) begin
        value = 1'b1;
        return MPACK_OK;
    end
    else begin
        return MPACK_WRONG_TYPE;
    end    
endfunction

function msgpack_result_t msgpack_dec::read_uint(ref longint unsigned value);
    byte unsigned symbol;
    read_uint = read(symbol);
    if(read_uint != MPACK_OK) begin
        return read_uint;
    end
    else if(~symbol & 8'h80) begin
        value = mpack_uint'(symbol);
        return MPACK_OK;
    end
    else if(symbol == MPACK_UINT8) begin
        read_uint = read(symbol);
        value = mpack_uint'(symbol);
    end
    else if(symbol == MPACK_UINT16) begin
        return read_and_shift_uint(value, 2);
    end
    else if(symbol == MPACK_UINT32) begin
        return read_and_shift_uint(value, 4);
    end
    else if(symbol == MPACK_UINT64) begin
        return read_and_shift_uint(value, 8);
    end
    else begin
        value = mpack_uint'(symbol);
        return MPACK_WRONG_TYPE;
    end    
endfunction

function msgpack_result_t msgpack_dec::read_int(ref longint value);
    byte unsigned symbol;
    longint unsigned uint_value;
    read_int = read_uint(uint_value);
    if(read_int inside {MPACK_OOB, MPACK_OK}) begin
        value = longint'(uint_value);
        return read_int;
    end
    else if((uint_value & 8'he0) == 8'he0) begin 
        value = longint'(uint_value);
        return MPACK_OK;
    end
    else if(uint_value == MPACK_INT8) begin
        read_int = read_and_shift_int(value, 1);
    end
    else if(uint_value == MPACK_INT16) begin
        read_int = read_and_shift_int(value, 2);
    end
    else if(uint_value == MPACK_INT32) begin
        read_int = read_and_shift_int(value, 4);
    end
    else if(uint_value == MPACK_INT64) begin
        read_int = read_and_shift_int(value, 8);
    end
    else begin
        return MPACK_WRONG_TYPE;
    end    
endfunction

function msgpack_result_t msgpack_dec::read_real(ref real value);
    byte unsigned symbol;
    longint unsigned uint_value;
    read_real = read(symbol);
    if(read_real != MPACK_OK) begin
        return read_real;
    end
    if(symbol != MPACK_FLOAT64) begin
        return MPACK_WRONG_TYPE;
    end
    read_real = read_and_shift_uint(uint_value, 8);
    value = $bitstoreal(uint_value);
endfunction

function msgpack_result_t msgpack_dec::read_shortreal(ref shortreal value);
    byte unsigned symbol;
    longint unsigned uint_value;
    read_shortreal = read(symbol);
    if(read_shortreal != MPACK_OK) begin
        return read_shortreal;
    end
    if(symbol != MPACK_FLOAT32) begin
        return MPACK_WRONG_TYPE;
    end
    read_shortreal = read_and_shift_uint(uint_value, 4);
    value = $bitstoshortreal(uint_value);
endfunction

function msgpack_result_t msgpack_dec::read_string(ref string value);
    byte unsigned symbol;
    longint unsigned str_size;
    read_string = read(symbol);
    if(read_string != MPACK_OK) begin
        return read_string;
    end
    if((symbol & MPACK_FIXSTR) == MPACK_FIXSTR) begin
        str_size = symbol & ~MPACK_FIXSTR;
    end
    else if(symbol == MPACK_STR8) begin
        read_string = read_and_shift_uint(str_size, 1);
    end
    else if(symbol == MPACK_STR16) begin
        read_string = read_and_shift_uint(str_size, 2);
    end
    else if(symbol == MPACK_STR32) begin
        read_string = read_and_shift_uint(str_size, 4);
    end
    else begin
        return MPACK_WRONG_TYPE;
    end
    for(longint unsigned i = 0; i < str_size; i++) begin
        read_string = read(symbol);
        if(read_string != MPACK_OK) return read_string;
        value = {value, symbol};
    end
endfunction