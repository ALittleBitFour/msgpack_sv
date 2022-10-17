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

`ifndef MSGPACK_TREE__SV
`define MSGPACK_TREE__SV

class msgpack_tree extends uvm_object;
    msgpack_collection_node _root;
    protected msgpack_dec dec;
    msgpack_enc enc;

    extern function new(string name = "msgpack_node");
    extern function void build_tree(msgpack_buffer buffer);
    extern function void build_msg();

    extern protected function void parse(msgpack_collection_node root, int unsigned size);
    extern protected function void parse_tree(msgpack_collection_node root);
    extern protected function void set_node_info(msgpack_node_base node, msgpack_collection_node root);

    `uvm_object_utils(msgpack_tree)
endclass

function msgpack_tree::new(string name = "msgpack_node");
    super.new(name);
endfunction

function void msgpack_tree::build_tree(msgpack_buffer buffer);
    dec = msgpack_dec::type_id::create("dec");
    dec.set_buffer(buffer);
    _root = msgpack_array_node::new("root");
    parse(_root, -1);
    if(!$cast(_root, _root.children[0])) begin
        `uvm_fatal(get_name(), "First element must be a collection")
    end
    _root.parent = null;
endfunction

function void msgpack_tree::parse(msgpack_collection_node root, int unsigned size);
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

function void msgpack_tree::set_node_info(msgpack_node_base node, msgpack_collection_node root);
    node.parent = root;
    root.children.push_back(node);
    if(root.node_type == MSGPACK_NODE_MAP && root.children.size() % 2 == 0) begin
        msgpack_map_node map;
        $cast(map, root);
        map.create_pair_from_children();
    end
endfunction

function void msgpack_tree::build_msg();
    enc = msgpack_enc::type_id::create("enc");
    parse_tree(_root);
endfunction

function void msgpack_tree::parse_tree(msgpack_collection_node root);
    if(root.node_type == MSGPACK_NODE_ARRAY) begin
        enc.write_array(root.size);
    end
    else if(root.node_type == MSGPACK_NODE_MAP) begin
        enc.write_map(root.size);
    end
    foreach(root.children[i]) begin
        case(root.children[i].node_type) 
            MSGPACK_NODE_INT: enc.write_int(msgpack_int_node::extract_value(root.children[i]));
            MSGPACK_NODE_UINT: enc.write_uint(msgpack_uint_node::extract_value(root.children[i]));
            MSGPACK_NODE_REAL: enc.write_real(msgpack_real_node::extract_value(root.children[i]));
            MSGPACK_NODE_SHORTREAL: enc.write_shortreal(msgpack_shortreal_node::extract_value(root.children[i]));
            MSGPACK_NODE_STRING: enc.write_string(msgpack_string_node::extract_value(root.children[i]));
            MSGPACK_NODE_BOOL: enc.write_bool(msgpack_bool_node::extract_value(root.children[i]));
            MSGPACK_NODE_ARRAY: begin
                msgpack_collection_node colleciton_node;
                if(!$cast(colleciton_node, root.children[i])) begin
                    `uvm_fatal(get_name(), $sformatf("Can't cast to collection type. Node type is %s", root.node_type.name()))
                end
                parse_tree(colleciton_node);
            end
            MSGPACK_NODE_MAP: begin
                msgpack_collection_node colleciton_node;
                if(!$cast(colleciton_node, root.children[i])) begin
                    `uvm_fatal(get_name(), $sformatf("Can't cast to collection type. Node type is %s", root.node_type.name()))
                end
                parse_tree(colleciton_node);
            end
            MSGPACK_NODE_BIN: enc.write_bin(msgpack_bin_node::extract_value(root.children[i]));
            // MSGPACK_NODE_EXT: // TODO implement ext support
            default: `uvm_fatal(get_name(), $sformatf("Unexpected type %s", root.children[i].node_type.name()))
        endcase
    end
endfunction

`endif