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