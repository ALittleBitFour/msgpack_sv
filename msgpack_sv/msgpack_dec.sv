class msgpack_dec extends uvm_object;
    struct {int unsigned offset;} state;

    msgpack_result_t last_result;
    protected mpack_buffer buffer;

    extern function new(string name = "msgpack_dec");

    extern function void set_buffer(byte unsigned buffer[$]);

    extern function void             read_nil();
    extern function bit              read_bool();
    extern function longint          read_int();
    extern function longint unsigned read_uint();
    extern function real             read_real();
    extern function shortreal        read_shortreal();
    extern function string           read_string();
    extern function mpack_bin        read_bin();
    extern function int unsigned     read_array();
    extern function int unsigned     read_map();

    extern protected function byte unsigned    read();
    extern protected function longint unsigned read_and_shift_uint(byte unsigned valid_byte);
    extern protected function longint          read_and_shift_int(byte unsigned valid_byte);

    `uvm_object_utils(msgpack_dec)
endclass

function msgpack_dec::new(string name = "msgpack_dec");
    super.new(name);
    state.offset = 0;
endfunction

function void msgpack_dec::set_buffer(byte unsigned buffer[$]);
    this.buffer = buffer;
endfunction

function byte unsigned msgpack_dec::read();
    `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
    if(state.offset >= buffer.size()) begin
        last_result = MPACK_OOB;
        `uvm_error(get_name(), $sformatf("MPack decoding error. Type: %s", last_result.name()))
    end
    `endif
    read = buffer[state.offset];
    state.offset++;
    last_result = MPACK_OK;
endfunction

function longint unsigned msgpack_dec::read_and_shift_uint(input byte unsigned valid_byte);
    read_and_shift_uint = 0;
    read_and_shift_uint = MPACK_OK;
    repeat(valid_byte) begin
        `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
        if(state.offset >= buffer.size()) begin
            last_result = MPACK_OOB;
            `uvm_error(get_name(), $sformatf("MPack decoding error. Type: %s", last_result.name()))
        end
        `endif
        read_and_shift_uint = {read_and_shift_uint, buffer[state.offset]};
        state.offset++;
    end
endfunction

function longint msgpack_dec::read_and_shift_int(input byte unsigned valid_byte);
    last_result = MPACK_OK;
    read_and_shift_int = 0;
    for(int i = 0; i < valid_byte; i++) begin
        `ifndef MSGPACK_SKIP_CHECK_BUFFER_SIZE
        if(state.offset >= buffer.size()) begin
            last_result = MPACK_OOB;
            `uvm_error(get_name(), $sformatf("MPack decoding error. Type: %s", last_result.name()))
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
    if(last_result == MPACK_OK) begin
        if(symbol == MPACK_NIL) begin
            last_result = MPACK_OK;
        end
        else begin
            last_result = MPACK_WRONG_TYPE;
        end
    end   
endfunction

function bit msgpack_dec::read_bool();
    byte unsigned symbol = read();
    if(last_result != MPACK_OK) begin
        return read_bool;
    end
    else if(symbol == MPACK_FALSE) begin
        read_bool = 1'b0;
        last_result = MPACK_OK;
    end
    else if(symbol == MPACK_TRUE) begin
        read_bool = 1'b1;
        last_result = MPACK_OK;
    end
    else begin
        last_result = MPACK_WRONG_TYPE;
    end    
endfunction

function longint unsigned msgpack_dec::read_uint();
    byte unsigned symbol;
    symbol = read();
    if(last_result != MPACK_OK) begin
        return 0;
    end
    else if(~symbol & 8'h80) begin
        last_result = MPACK_OK;
        return mpack_uint32'(symbol);
    end
    else if(symbol == MPACK_UINT8) begin
        return mpack_uint32'(read());
    end
    else if(symbol == MPACK_UINT16) begin
        return read_and_shift_uint(2);
    end
    else if(symbol == MPACK_UINT32) begin
        return read_and_shift_uint(4);
    end
    else if(symbol == MPACK_UINT64) begin
        return read_and_shift_uint(8);
    end
    else begin
        read_uint = mpack_uint32'(symbol);
        last_result = MPACK_WRONG_TYPE;
    end    
endfunction

function longint msgpack_dec::read_int();
    byte unsigned symbol;
    longint unsigned uint_value = read_uint();
    if(last_result inside {MPACK_OOB, MPACK_OK}) begin
        return longint'(uint_value);
    end
    else if((uint_value & 8'he0) == 8'he0) begin 
        last_result = MPACK_OK;
        return longint'(uint_value);
    end
    else if(uint_value == MPACK_INT8) begin
        return read_and_shift_int(1);
    end
    else if(uint_value == MPACK_INT16) begin
        return read_and_shift_int(2);
    end
    else if(uint_value == MPACK_INT32) begin
        return read_and_shift_int(4);
    end
    else if(uint_value == MPACK_INT64) begin
        return read_and_shift_int(8);
    end
    else begin
        last_result = MPACK_WRONG_TYPE;
    end    
endfunction

function real msgpack_dec::read_real();
    byte unsigned symbol;
    longint unsigned uint_value;
    symbol = read();
    if(last_result != MPACK_OK) begin
        return 0;
    end
    if(symbol != MPACK_FLOAT64) begin
        last_result = MPACK_WRONG_TYPE;
    end
    uint_value = read_and_shift_uint(8);
    return $bitstoreal(uint_value);
endfunction

function shortreal msgpack_dec::read_shortreal();
    byte unsigned symbol;
    longint unsigned uint_value;
    symbol = read();
    if(read_shortreal != MPACK_OK) begin
        return 0;
    end
    if(symbol != MPACK_FLOAT32) begin
        last_result = MPACK_WRONG_TYPE;
    end
    uint_value = read_and_shift_uint(4);
    return $bitstoshortreal(uint_value);
endfunction

function string msgpack_dec::read_string();
    byte unsigned symbol;
    longint unsigned str_size;
    symbol = read();
    if(last_result != MPACK_OK) begin
        return "";
    end
    if((symbol & 8'hf0) == MPACK_FIXSTR) begin
        str_size = symbol & ~MPACK_FIXSTR;
    end
    else if(symbol == MPACK_STR8) begin
        str_size = read_and_shift_uint(1);
    end
    else if(symbol == MPACK_STR16) begin
        str_size = read_and_shift_uint(2);
    end
    else if(symbol == MPACK_STR32) begin
        str_size = read_and_shift_uint(4);
    end
    else begin
        last_result = MPACK_WRONG_TYPE;
    end
    for(longint unsigned i = 0; i < str_size; i++) begin
        symbol = read();
        if(last_result != MPACK_OK) return "";
        read_string = {read_string, symbol};
    end
endfunction

function mpack_bin msgpack_dec::read_bin();
    byte unsigned symbol;
    longint unsigned bin_size;
    symbol = read();
    if(last_result != MPACK_OK) begin
        return {};
    end
    if(symbol == MPACK_BIN8) begin
        bin_size = read_and_shift_uint(1);
    end
    else if(symbol == MPACK_BIN16) begin
        bin_size = read_and_shift_uint(2);
    end
    else if(symbol == MPACK_BIN32) begin
        bin_size = read_and_shift_uint(4);
    end
    else begin
        last_result = MPACK_WRONG_TYPE;
    end
    for(longint unsigned i = 0; i < bin_size; i++) begin
        symbol = read();
        if(last_result != MPACK_OK) return {};
        read_bin = {read_bin, symbol};
    end
endfunction

function int unsigned msgpack_dec::read_array();
    byte unsigned symbol;
    longint unsigned uint_size;
    symbol = read();
    if(last_result != MPACK_OK) begin
        return 0;
    end
    if((symbol & 8'hf0) == MPACK_FIXARRAY) begin
        return symbol & ~MPACK_FIXARRAY;
    end
    else if(symbol == MPACK_ARRAY16) begin
        uint_size = read_and_shift_uint(2);
        return mpack_uint32'(uint_size);
    end
    else if(symbol == MPACK_ARRAY32) begin
        uint_size = read_and_shift_uint(4);
        return mpack_uint32'(uint_size);
    end
    else begin
        last_result = MPACK_WRONG_TYPE;
    end
endfunction

function int unsigned msgpack_dec::read_map();
    byte unsigned symbol;
    longint unsigned uint_size;
    symbol = read();
    if(last_result != MPACK_OK) begin
        return 0;
    end
    if((symbol & 8'hf0) == MPACK_FIXMAP) begin
        return symbol & ~MPACK_FIXMAP;
    end
    else if(symbol == MPACK_MAP16) begin
        uint_size = read_and_shift_uint(2);
        return mpack_uint32'(uint_size);
    end
    else if(symbol == MPACK_MAP32) begin
        uint_size = read_and_shift_uint(4);
        return mpack_uint32'(uint_size);
    end
    else begin
        last_result = MPACK_WRONG_TYPE;
    end
endfunction