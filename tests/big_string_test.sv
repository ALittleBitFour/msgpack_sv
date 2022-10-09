`ifndef BIG_STRING_TEST__SV
`define BIG_STRING_TEST__SV

class big_string_test extends base_test;

    function new(string name = "big_string_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        msgpack_bin bin_data = '{1<<16{5}};

        enc.write_array_begin();
        enc.write_string({1<<8{"b"}});
        enc.write_string({1<<16{"c"}});
        enc.write_bin(bin_data);
        enc.write_array_end();

        dec.set_buffer(enc.get_buffer());

        `check_decoding(msgpack_uint32, dec.read_array, 3, %0d);
        `check_decoding(string, dec.read_string, {1<<8{"b"}}, %s);
        `check_decoding(string, dec.read_string, {1<<16{"c"}}, %s);
        `check_decoding(msgpack_bin, dec.read_bin, bin_data, %p);
    endtask

    `uvm_component_utils(big_string_test)
endclass

`endif