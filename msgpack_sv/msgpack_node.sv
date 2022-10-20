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

`ifndef MSGPACK_NODE__SV
`define MSGPACK_NODE__SV

`define msgpack_node_utils(T, Tval) \
// Function: create_node \
// Create node with predefined type \
static function msgpack_node_base create_node(Tval value); \
    T tmp = new(); \
    tmp.value = value; \
    return tmp; \
endfunction \
\
// Function: extract_value \
// Extract value from the node \
static function Tval extract_value(msgpack_node_base node); \
    T tmp; \
    if(!$cast(tmp, node)) `uvm_fatal("MsgPack API", "Wrong argument type") \
    return tmp.value; \
endfunction

// Class: msgpack_node_base
// Base class for all node types. Contains type of node and pointer to parent node
class msgpack_node_base extends uvm_object;
    msgpack_node_base parent;
    msgpack_node_t node_type;

    function new(string name = "msgpack_node");
        super.new(name);
    endfunction

    virtual function void do_print(uvm_printer printer);
        printer.print_string("type", node_type.name());
    endfunction

    `uvm_object_utils(msgpack_node_base)
endclass

// Class: msgpack_node
// Typed class that contains value. It's not recomended for users
class msgpack_node#(type T = int) extends msgpack_node_base;
    T value;

    function new(string name = "msgpack_node");
        super.new(name);
    endfunction

    function void do_print (uvm_printer printer);
        super.do_print(printer);
        printer.print_string("value", $sformatf("%0p", value));
    endfunction

    function string convert2string();
        return $sformatf("%p", value);
    endfunction

    `uvm_object_param_utils(msgpack_node#(T))
endclass

// Class: msgpack_int_node
// Implements <create_node> and <extract_value> function for 
// Integer nodes. 
class msgpack_int_node extends msgpack_node#(longint);
    function new(string name = "msgpack_int_node");
        super.new(name);
        node_type = MSGPACK_NODE_INT;
    endfunction

    `uvm_object_param_utils(msgpack_int_node)
    `msgpack_node_utils(msgpack_int_node, longint)
endclass

// Class: msgpack_uint_node
// Implements <create_node> and <extract_value> function for 
// unsigned Integer nodes. 
class msgpack_uint_node extends msgpack_node#(longint unsigned);
    function new(string name = "msgpack_uint_node");
        super.new(name);
        node_type = MSGPACK_NODE_UINT;
    endfunction

    `uvm_object_param_utils(msgpack_uint_node)
    `msgpack_node_utils(msgpack_uint_node, longint unsigned)
endclass

// Class: msgpack_bool_node
// Implements <create_node> and <extract_value> function for 
// Boolean nodes. 
class msgpack_bool_node extends msgpack_node#(bit);
    function new(string name = "msgpack_bool_node");
        super.new(name);
        node_type = MSGPACK_NODE_BOOL;
    endfunction

    `uvm_object_param_utils(msgpack_bool_node)
    `msgpack_node_utils(msgpack_bool_node, bit)
endclass

// Class: msgpack_string_node
// Implements <create_node> and <extract_value> function for 
// String nodes. 
class msgpack_string_node extends msgpack_node#(string);
    function new(string name = "msgpack_string_node");
        super.new(name);
        node_type = MSGPACK_NODE_STRING;
    endfunction

    `uvm_object_param_utils(msgpack_string_node)
    `msgpack_node_utils(msgpack_string_node, string)
endclass

// Class: msgpack_shortreal_node
// Implements <create_node> and <extract_value> function for 
// Shortreal nodes. 
class msgpack_shortreal_node extends msgpack_node#(shortreal);
    function new(string name = "msgpack_shortreal_node");
        super.new(name);
        node_type = MSGPACK_NODE_SHORTREAL;
    endfunction

    `uvm_object_param_utils(msgpack_shortreal_node)
    `msgpack_node_utils(msgpack_shortreal_node, shortreal)
endclass

// Class: msgpack_real_node
// Implements <create_node> and <extract_value> function for 
// Real nodes. 
class msgpack_real_node extends msgpack_node#(real);
    function new(string name = "msgpack_real_node");
        super.new(name);
        node_type = MSGPACK_NODE_REAL;
    endfunction

    `uvm_object_param_utils(msgpack_real_node)
    `msgpack_node_utils(msgpack_real_node, real)
endclass

// Class: msgpack_bin_node
// Implements <create_node> and <extract_value> function for 
// Binary nodes. 
class msgpack_bin_node extends msgpack_node#(msgpack_bin);
    function new(string name = "msgpack_bin_node");
        super.new(name);
        node_type = MSGPACK_NODE_BIN;
    endfunction

    `uvm_object_param_utils(msgpack_bin_node)
    `msgpack_node_utils(msgpack_bin_node, msgpack_bin)
endclass

// Class: msgpack_collection_node
// Base class for collection nodes. Contains size attribute
// and children queue
class msgpack_collection_node extends msgpack_node_base;
    int unsigned size;
    msgpack_node_base children[$];

    function new(string name = "msgpack_collection_node");
        super.new(name);
    endfunction

    function void do_print (uvm_printer printer);
        super.do_print(printer);
        printer.print_string("size", $sformatf("%0p", size));
    endfunction

    `uvm_object_utils(msgpack_collection_node)
endclass

// Class: msgpack_array_node
// Array collection node.
class msgpack_array_node extends msgpack_collection_node;
    function new(string name = "msgpack_array_node");
        super.new(name);
        node_type = MSGPACK_NODE_ARRAY;
    endfunction

    function void do_print (uvm_printer printer);
        super.do_print(printer);
        foreach(children[i]) begin
            printer.print_object($sformatf("child_%0d", i), children[i]);
        end
    endfunction

    // Function: push
    // Push child node to the array
    function void push(msgpack_node_base child);
        children.push_back(child);
        size++;
    endfunction

    `uvm_object_utils(msgpack_array_node)
endclass

// Class: msgpack_map_node
// Map collection node.
class msgpack_map_node extends msgpack_collection_node;    
    class internal_map#(type T = int);
        msgpack_node_base map[T];

        function new();
        endfunction

        function void add_key_value(msgpack_node_base key, msgpack_node_base value);
            msgpack_node#(T) tmp;
            if(key.node_type inside {MSGPACK_NODE_ARRAY, MSGPACK_NODE_MAP, MSGPACK_NODE_BIN, MSGPACK_NODE_EXT}) begin
                map[key] = value;
            end
            else if($cast(tmp, key)) begin
               map[tmp.value] = value;
            end
            else begin
                `uvm_fatal("MsgPack API", $sformatf("Can't cast key in map node. Expected type: %s", key.node_type.name()))
            end
        endfunction

        function msgpack_node_base get_value(msgpack_node_base key);
            msgpack_node#(T) tmp;
            if(key.node_type inside {MSGPACK_NODE_ARRAY, MSGPACK_NODE_MAP, MSGPACK_NODE_BIN, MSGPACK_NODE_EXT}) begin
                return map[key];
            end
            if(!$cast(tmp, key)) begin
                `uvm_fatal("MsgPack API", "Can't cast key in map node")
            end
            return map[tmp.value];
        endfunction
    endclass

    protected internal_map#(longint) int_map;
    protected internal_map#(longint unsigned) uint_map;
    protected internal_map#(string) string_map;
    protected internal_map#(bit) bool_map;
    protected internal_map#(msgpack_node_base) array_map;

    function new(string name = "msgpack_map_node");
        super.new(name);
        node_type = MSGPACK_NODE_MAP;
        int_map = new();
        uint_map = new();
        string_map = new();
        bool_map = new();
        array_map = new();
    endfunction

    // Function: add_key_value
    // Add pair key, value to the map
    function void add_key_value(msgpack_node_base key, msgpack_node_base value);
        key.parent = this;
        value.parent = key;
        children.push_back(key);
        children.push_back(value);
        case(key.node_type) inside
            MSGPACK_NODE_INT: int_map.add_key_value(key, value);
            MSGPACK_NODE_UINT: uint_map.add_key_value(key, value);
            MSGPACK_NODE_STRING: string_map.add_key_value(key, value);
            MSGPACK_NODE_BOOL: bool_map.add_key_value(key, value);
            [MSGPACK_NODE_ARRAY: MSGPACK_NODE_EXT]: array_map.add_key_value(key, value);
            default: `uvm_fatal(get_name(), "Unexpected node type")
        endcase
        size++;
    endfunction

    function void create_pair_from_children();
        msgpack_node_base key, value;
        key = children[children.size() - 2];
        value = children[children.size() - 1];
        key.parent = this;
        value.parent = key;
        case(key.node_type)
            MSGPACK_NODE_INT: int_map.add_key_value(key, value);
            MSGPACK_NODE_UINT: uint_map.add_key_value(key, value);
            MSGPACK_NODE_STRING: string_map.add_key_value(key, value);
            MSGPACK_NODE_BOOL: bool_map.add_key_value(key, value);
            MSGPACK_NODE_ARRAY : MSGPACK_NODE_EXT: array_map.add_key_value(key, value);
            default: `uvm_fatal(get_name(), "Unexpected node type")
        endcase
    endfunction;

    // Function: get_value
    function msgpack_node_base get_value(msgpack_node_base key);
        case(key.node_type)
            MSGPACK_NODE_INT: return int_map.get_value(key);
            MSGPACK_NODE_UINT: return uint_map.get_value(key);
            MSGPACK_NODE_STRING: return string_map.get_value(key);
            MSGPACK_NODE_BOOL: return bool_map.get_value(key);
            MSGPACK_NODE_ARRAY : MSGPACK_NODE_EXT: return array_map.get_value(key);
            default: `uvm_fatal(get_name(), "Unexpected node type")
        endcase
    endfunction

    function void do_print (uvm_printer printer);
        super.do_print(printer);
        foreach(int_map.map[i]) begin
            printer.print_string("Key", $sformatf("%h", i));
            printer.print_object("Value ", int_map.map[i]);
        end
        foreach(uint_map.map[i]) begin
            printer.print_string("Key", $sformatf("%h", i));
            printer.print_object("Value", uint_map.map[i]);
        end
        foreach(string_map.map[i]) begin
            printer.print_string("Key", $sformatf("%s", i));
            printer.print_object("Value", string_map.map[i]);
        end
        foreach(bool_map.map[i]) begin
            printer.print_string("Key", $sformatf("%d", i));
            printer.print_object("Value", bool_map.map[i]);
        end
        foreach(array_map.map[i]) begin
            printer.print_object("Key", array_map.map[i].parent);
            printer.print_object("Value", array_map.map[i]);
        end
    endfunction

    `uvm_object_utils(msgpack_map_node)
endclass

`undef msgpack_node_utils
`endif