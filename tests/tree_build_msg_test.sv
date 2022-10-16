`ifndef TREE_BUILD_MSG_TEST__SV
`define TREE_BUILD_MSG_TEST__SV

class tree_build_msg_test extends base_test;
    msgpack_tree tree;
    msgpack_map_node map;

    function new(string name = "tree_build_msg_test", uvm_component parent);
        super.new(name, parent);
        tree = new("tree");
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
        enc.write_string({10{"a"}});
        enc.write_array_end();

        tree.build_tree(enc.get_buffer());

        if(!$cast(map, tree._root)) `uvm_fatal(get_name(), "First node in tree isn't a map")
        map.add_key_value(msgpack_string_node::create_node("New entry"), msgpack_int_node::create_node(15));
        map.add_key_value(msgpack_string_node::create_node("New-new entry"), msgpack_string_node::create_node("Here we go again"));

        tree.build_msg();

        print_buffer(tree.enc);
    endtask

    `uvm_component_utils(tree_build_msg_test)
endclass

`endif