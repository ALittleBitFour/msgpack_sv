`ifndef MSGPACK_TREE__SV
`define MSGPACK_TREE__SV

class msgpack_tree extends uvm_object;
    msgpack_node_base _root;
    protected msgpack_dec dec;

    extern function new(string name = "msgpack_node");
    extern function void build(msgpack_buffer buffer);

    extern protected function void parse(msgpack_node_base root, int unsigned size);
    extern protected function void set_node_info(msgpack_node_base node, msgpack_node_base root, msgpack_node_t node_t);

    `uvm_object_utils(msgpack_tree)
endclass

function msgpack_tree::new(string name = "msgpack_node");
    super.new(name);
endfunction

function void msgpack_tree::build(msgpack_buffer buffer);
    dec = msgpack_dec::type_id::create("dec");
    dec.set_buffer(buffer);
    _root = new("root");
    parse(_root, -1);
endfunction

function void msgpack_tree::parse(msgpack_node_base root, int unsigned size);
    byte unsigned symbol;
    for(int unsigned i = 0; i < size; i++) begin
        if(!dec.peek(symbol)) return;
        // Check fixed types
        if(symbol >> 7 == 0) begin
            msgpack_node#(longint unsigned) node = new("uint_node");
            node.value = dec.read_uint();
            set_node_info(node, root, MSGPACK_NODE_INT);
        end
        else if(symbol >> 5 == 'h7) begin
            msgpack_node#(longint) node = new("int_node");
            node.value = dec.read_uint();
            set_node_info(node, root, MSGPACK_NODE_UINT);
        end
        else if(symbol >> 5 == 'h5) begin
            msgpack_node#(string) node = new("str_node");
            node.value = dec.read_string();
            set_node_info(node, root, MSGPACK_NODE_STRING);
        end
        else if(symbol >> 4 == 'h9) begin
            msgpack_node#(int unsigned) node = new("array_node");
            node.value = dec.read_array();
            parse(node, node.value);
            set_node_info(node, root, MSGPACK_NODE_ARRAY);
        end
        else if(symbol >> 4 == 'h8) begin
            msgpack_node#(int unsigned) node = new("map_node");
            node.value = dec.read_map();
            parse(node, node.value*2);
            set_node_info(node, root, MSGPACK_NODE_MAP);
        end
        else begin
            case(symbol) inside
                MSGPACK_FALSE, MSGPACK_TRUE: begin
                    msgpack_node#(bit) node = new("bool_node");
                    node.value = dec.read_bool();
                    set_node_info(node, root, MSGPACK_NODE_BOOL);
                end
                [MSGPACK_UINT8: MSGPACK_UINT64]: begin
                    msgpack_node#(longint unsigned) node = new("uint_node");
                    node.value = dec.read_uint();
                    set_node_info(node, root, MSGPACK_NODE_UINT);
                end
                [MSGPACK_INT8: MSGPACK_INT64]: begin
                    msgpack_node#(longint) node = new("int_node");
                    node.value = dec.read_int();
                    set_node_info(node, root, MSGPACK_NODE_INT);
                end
                MSGPACK_FLOAT32: begin
                    msgpack_node#(shortreal) node = new("shortreal_node");
                    node.value = dec.read_shortreal();
                    set_node_info(node, root, MSGPACK_NODE_REAL);
                end
                MSGPACK_FLOAT64: begin
                    msgpack_node#(real) node = new("real_node");
                    node.value = dec.read_real();
                    set_node_info(node, root, MSGPACK_NODE_REAL);
                end
                [MSGPACK_BIN8: MSGPACK_BIN32]: begin
                    msgpack_node#(msgpack_bin) node = new("bin_node");
                    node.value = dec.read_bin();
                    set_node_info(node, root, MSGPACK_NODE_BIN);
                end
                [MSGPACK_STR8: MSGPACK_STR32]: begin
                    msgpack_node#(string) node = new("str_node");
                    node.value = dec.read_string();
                    set_node_info(node, root, MSGPACK_NODE_STRING);
                end
                [MSGPACK_ARRAY16: MSGPACK_ARRAY32]: begin
                    msgpack_node#(int unsigned) node = new("array_node");
                    node.value = dec.read_array();
                    set_node_info(node, root, MSGPACK_NODE_ARRAY);
                    parse(node, node.value);
                end
                [MSGPACK_MAP16: MSGPACK_MAP32]: begin
                    msgpack_node#(int unsigned) node = new("map_node");
                    node.value = dec.read_map();
                    set_node_info(node, root, MSGPACK_NODE_MAP);
                    parse(node, node.value*2);
                end
                default: `uvm_error(get_name(), $sformatf("Wrong Message pack type: %h", symbol))
            endcase
        end
    end
endfunction

function void msgpack_tree::set_node_info(msgpack_node_base node, msgpack_node_base root, msgpack_node_t node_t);
    node.node_type = node_t;
    node.parent = root;
    root.children.push_back(node);
endfunction

`endif