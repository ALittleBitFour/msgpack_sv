`ifndef MSGPACK_TREE__SV
`define MSGPACK_TREE__SV

class msgpack_tree extends uvm_object;
    msgpack_node_base _root;
    protected msgpack_dec dec;

    extern function new(string name = "msgpack_node");
    extern function void build(msgpack_buffer buffer);

    extern protected function void parse(msgpack_node_base root, int unsigned size);
    extern protected function void set_node_info(msgpack_node_base node, msgpack_node_base root);

    `uvm_object_utils(msgpack_tree)
endclass

function msgpack_tree::new(string name = "msgpack_node");
    super.new(name);
endfunction

function void msgpack_tree::build(msgpack_buffer buffer);
    dec = msgpack_dec::type_id::create("dec");
    dec.set_buffer(buffer);
    _root = msgpack_array_node::new("root");
    parse(_root, -1);
    _root = _root.children[0];
    _root.parent = null;
endfunction

function void msgpack_tree::parse(msgpack_node_base root, int unsigned size);
    byte unsigned symbol;
    for(int unsigned i = 0; i < size; i++) begin
        if(!dec.peek(symbol)) return;
        // Check fixed types
        if(symbol >> 7 == 0) begin
            msgpack_uint_node node = new("uint_node");
            node.value = dec.read_uint();
            set_node_info(node, root);
        end
        else if(symbol >> 5 == 'h7) begin
            msgpack_int_node node = new("int_node");
            node.value = dec.read_uint();
            set_node_info(node, root);
        end
        else if(symbol >> 5 == 'h5) begin
            msgpack_string_node node = new("str_node");
            node.value = dec.read_string();
            set_node_info(node, root);
        end
        else if(symbol >> 4 == 'h9) begin
            msgpack_array_node node = new("array_node");
            node.size = dec.read_array();
            parse(node, node.size);
            set_node_info(node, root);
        end
        else if(symbol >> 4 == 'h8) begin
            msgpack_map_node node = new("map_node");
            node.size = dec.read_map();
            parse(node, node.size*2);
            set_node_info(node, root);
        end
        else begin
            case(symbol) inside
                MSGPACK_FALSE, MSGPACK_TRUE: begin
                    msgpack_bool_node node = new("bool_node");
                    node.value = dec.read_bool();
                    set_node_info(node, root);
                end
                [MSGPACK_UINT8: MSGPACK_UINT64]: begin
                    msgpack_uint_node node = new("uint_node");
                    node.value = dec.read_uint();
                    set_node_info(node, root);
                end
                [MSGPACK_INT8: MSGPACK_INT64]: begin
                    msgpack_int_node node = new("int_node");
                    node.value = dec.read_int();
                    set_node_info(node, root);
                end
                MSGPACK_FLOAT32: begin
                    msgpack_shortreal_node node = new("shortreal_node");
                    node.value = dec.read_shortreal();
                    set_node_info(node, root);
                end
                MSGPACK_FLOAT64: begin
                    msgpack_real_node node = new("real_node");
                    node.value = dec.read_real();
                    set_node_info(node, root);
                end
                [MSGPACK_BIN8: MSGPACK_BIN32]: begin
                    msgpack_bin_node node = new("bin_node");
                    node.value = dec.read_bin();
                    set_node_info(node, root);
                end
                [MSGPACK_STR8: MSGPACK_STR32]: begin
                    msgpack_string_node node = new("str_node");
                    node.value = dec.read_string();
                    set_node_info(node, root);
                end
                [MSGPACK_ARRAY16: MSGPACK_ARRAY32]: begin
                    msgpack_array_node node = new("array_node");
                    node.size = dec.read_array();
                    set_node_info(node, root);
                    parse(node, node.size);
                end
                [MSGPACK_MAP16: MSGPACK_MAP32]: begin
                    msgpack_map_node node = new("map_node");
                    node.size = dec.read_map();
                    set_node_info(node, root);
                    parse(node, node.size*2);
                end
                default: `uvm_error(get_name(), $sformatf("Wrong Message pack type: %h", symbol))
            endcase
        end
    end
endfunction

function void msgpack_tree::set_node_info(msgpack_node_base node, msgpack_node_base root);
    node.parent = root;
    root.children.push_back(node);
    if(root.node_type == MSGPACK_NODE_MAP && root.children.size() % 2 == 0) begin
        msgpack_map_node map;
        $cast(map, root);
        map.create_pair_from_children();
    end
endfunction

`endif