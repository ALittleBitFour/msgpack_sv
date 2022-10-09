`ifndef TREE_PARSE_TEST__SV
`define TREE_PARSE_TEST__SV

class tree_parse_test extends base_test;
    msgpack_tree tree;

    function new(string name = "tree_parse_test", uvm_component parent);
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
        enc.write_string({100{"a"}});
        enc.write_array_end();

        tree.build(enc.get_buffer());

        `uvm_info(get_name(), tree._root.sprint(), UVM_NONE)
    endtask

    `uvm_component_utils(tree_parse_test)
endclass

`endif