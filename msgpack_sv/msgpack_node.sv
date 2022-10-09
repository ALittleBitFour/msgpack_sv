`ifndef MSGPACK_NODE__SV
`define MSGPACK_NODE__SV

class msgpack_node_base extends uvm_object;
    msgpack_node_base children[$];
    msgpack_node_base parent;
    msgpack_node_t node_type;

    extern function new(string name = "msgpack_node");
    extern virtual function void do_print(uvm_printer printer);

    `uvm_object_utils(msgpack_node_base)
endclass

function msgpack_node_base::new(string name = "msgpack_node");
    super.new(name);
endfunction

function void msgpack_node_base::do_print (uvm_printer printer);
    super.do_print(printer);
    printer.print_string("type", node_type.name());
    printer.print_object("parent", parent);
    foreach(children[i]) begin
        printer.print_object($sformatf("child_%0d", i), children[i]);
    end
endfunction

class msgpack_node#(type T = int) extends msgpack_node_base;
    T value;

    function new(string name = "msgpack_node");
        super.new(name);
    endfunction

    function void do_print (uvm_printer printer);
        printer.print_string("value", $sformatf("%0p", value));
        super.do_print(printer);
    endfunction

    `uvm_object_param_utils(msgpack_node#(T))
endclass

`endif