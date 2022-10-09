`ifndef DIRECT_SET_TEST__SV
`define DIRECT_SET_TEST__SV

class direct_set_test extends base_test;

    function new(string name = "direct_set_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        enc.write_map(1);
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
        enc.write_array_end();

        dec.set_buffer(enc.get_buffer());

        `check_decoding(msgpack_uint32, dec.read_map, 1, %0d);
        `check_decoding(msgpack_uint32, dec.read_array, 6, %0d);
        `check_decoding(bit, dec.read_bool, 1'b1, %0d);
        `check_decoding(bit, dec.read_bool, 1'b0, %0d);
        `check_decoding(longint, dec.read_int, -100, %0d);
        `check_decoding(longint, dec.read_int, 52, %0d);
        `check_decoding(real, dec.read_real, -1.14, %f);
        `check_decoding(shortreal, dec.read_shortreal, -1.15, %f); // It seems that Questa use real instead of shortreal, so we have an error if use $shortrealtobits
        `check_decoding(msgpack_uint32, dec.read_map, 2, %0d);
        `check_decoding(string, dec.read_string, "Hola Comrade!", %s);
        `check_decoding(longint, dec.read_int, 1000, %d);
        `check_decoding(string, dec.read_string, "Hello", %s);
        `check_decoding(msgpack_uint32, dec.read_array, 1, %0d);
        `check_decoding(string, dec.read_string, {100{"a"}}, %s);
    endtask

    `uvm_component_utils(direct_set_test)
endclass

`endif