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

`ifndef TREE_BUILD_MSG_TEST__SV
`define TREE_BUILD_MSG_TEST__SV

class tree_build_msg_test extends base_test;
    function new(string name = "tree_build_msg_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        msgpack_tree tree = new();
        msgpack_map_node map;
        msgpack_array_node array;

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
        enc.write_string({10{"a"}});
        enc.write_array_end();

        tree.build_tree(enc.get_buffer());

        if(!$cast(map, tree.root)) `uvm_fatal(get_name(), "First node in tree isn't a map")
        map.set_key_value(msgpack_string_node::create_node("New entry"), msgpack_int_node::create_node(15));
        map.set_key_value(msgpack_string_node::create_node("New-new entry"), msgpack_string_node::create_node("Here we go again"));
        map.set_value_of_string("Last string", msgpack_uint_node::create_node(50000));
        array = new();
        array.push(msgpack_bool_node::create_node(1'b1));
        array.push(msgpack_string_node::create_node("Item"));
        array.push(msgpack_int_node::create_node(-15));
        map.set_key_value(msgpack_int_node::create_node(100500), array);

        tree.build_msg();

        print_buffer(tree.enc);
    endtask

    `uvm_component_utils(tree_build_msg_test)
endclass

`endif