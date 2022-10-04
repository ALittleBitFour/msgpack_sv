`include "uvm_pkg.sv"

module top;

import uvm_pkg::*;
import msgpack_pkg::*;

function void check_result(msgpack_result_t result);
    case(result)
        MPACK_OK: begin
            `uvm_info("TOP", "Fine", UVM_DEBUG)
        end
        MPACK_OOB: begin
            `uvm_info("TOP", "OOB", UVM_DEBUG)
        end
        MPACK_WRONG_TYPE: begin
            `uvm_info("TOP", "Wrong type", UVM_DEBUG)
        end
    endcase
endfunction

`define check_decoding(VAL, FUNC, EXP, FORMAT) \
begin\
automatic VAL act_value;\
check_result(FUNC(act_value));\
if(act_value != VAL'(EXP)) begin\
    automatic string format_str = `"FORMAT`"; \
    automatic string type_str = `"VAL`"; \
    `uvm_error("TOP", $sformatf({"Type: %s. Actual: ", format_str, " Expected: ", format_str}, type_str, act_value, EXP))\
end\
end

typedef byte unsigned bin_array_t[];

initial begin
    automatic bin_array_t bin_data = '{1<<16{5}};
    automatic msgpack_enc enc = new("enc");
    automatic msgpack_dec dec = new("dec");

    enc.write_map_begin();
    enc.write_array(6);
    enc.write_bool(1'b1);
    enc.write_bool(1'b0);
    enc.write_int(-100);
    enc.write_int(52);
    enc.write_real(-1.14);
    enc.write_shortreal(-1.15);
    enc.write_map(2);
    enc.write_string("Hola Comrade!");
    enc.write_int(1000);
    enc.write_string("Hello");
    enc.write_array_begin();
    enc.write_string({100{"a"}});
    // enc.write_string({1<<8{"b"}});
    // enc.write_string({1<<16{"c"}});
    // enc.write_bin(bin_data);
    enc.write_array_end();
    enc.write_map_end();

    begin
        automatic mpack_buffer buffer = enc.get_buffer();
        automatic string str;
        foreach(buffer[i]) begin
            str = $sformatf("%s %h", str, buffer[i]);
        end
        `uvm_info("TOP", str, UVM_NONE)
    end

    dec.set_buffer(enc.get_buffer());
    `check_decoding(mpack_uint32, dec.read_map, 1, %0d);
    `check_decoding(mpack_uint32, dec.read_array, 6, %0d);
    `check_decoding(bit, dec.read_bool, 1'b1, %0d);
    `check_decoding(bit, dec.read_bool, 1'b0, %0d);
    `check_decoding(longint, dec.read_int, -100, %0d);
    `check_decoding(longint, dec.read_int, 52, %0d);
    `check_decoding(real, dec.read_real, -1.14, %f);
    `check_decoding(shortreal, dec.read_shortreal, -1.15, %f); // It seems that Questa use real instead of shortreal, so we have an error if use $shortrealtobits
    `check_decoding(mpack_uint32, dec.read_map, 2, %0d);
    `check_decoding(string, dec.read_string, "Hola Comrade!", %s);
    `check_decoding(longint, dec.read_int, 1000, %d);
    `check_decoding(string, dec.read_string, "Hello", %s);
    `check_decoding(mpack_uint32, dec.read_array, 1, %0d);
    `check_decoding(string, dec.read_string, {100{"a"}}, %s);
    // `check_decoding(string, dec.read_string, {1<<8{"b"}}, %s);
    // `check_decoding(string, dec.read_string, {1<<16{"c"}}, %s);
    // `check_decoding(bin_array_t, dec.read_bin, bin_data, %p);
end

endmodule