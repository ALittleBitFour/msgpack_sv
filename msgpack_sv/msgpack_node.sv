`ifndef MSGPACK_NODE__SV
`define MSGPACK_NODE__SV

`define msgpack_node_utils(T, Tval) \
static function msgpack_node_base create_node(Tval value); \
    T tmp = new(); \
    tmp.value = value; \
    return tmp; \
endfunction \
\
static function Tval extract_value(T node); \
    return node.value; \
endfunction

class msgpack_node_base extends uvm_object;
    msgpack_node_base children[$];
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

class msgpack_int_node extends msgpack_node#(longint);
    function new(string name = "msgpack_int_node");
        super.new(name);
        node_type = MSGPACK_NODE_INT;
    endfunction

    `uvm_object_param_utils(msgpack_int_node)
    `msgpack_node_utils(msgpack_int_node, longint)
endclass

class msgpack_uint_node extends msgpack_node#(longint unsigned);
    function new(string name = "msgpack_uint_node");
        super.new(name);
        node_type = MSGPACK_NODE_UINT;
    endfunction

    `uvm_object_param_utils(msgpack_uint_node)
    `msgpack_node_utils(msgpack_uint_node, longint unsigned)
endclass

class msgpack_bool_node extends msgpack_node#(bit);
    function new(string name = "msgpack_bool_node");
        super.new(name);
        node_type = MSGPACK_NODE_BOOL;
    endfunction

    `uvm_object_param_utils(msgpack_bool_node)
    `msgpack_node_utils(msgpack_bool_node, bit)
endclass

class msgpack_string_node extends msgpack_node#(string);
    function new(string name = "msgpack_string_node");
        super.new(name);
        node_type = MSGPACK_NODE_STRING;
    endfunction

    `uvm_object_param_utils(msgpack_string_node)
    `msgpack_node_utils(msgpack_string_node, string)
endclass

class msgpack_shortreal_node extends msgpack_node#(shortreal);
    function new(string name = "msgpack_shortreal_node");
        super.new(name);
        node_type = MSGPACK_NODE_REAL;
    endfunction

    `uvm_object_param_utils(msgpack_shortreal_node)
    `msgpack_node_utils(msgpack_shortreal_node, shortreal)
endclass

class msgpack_real_node extends msgpack_node#(real);
    function new(string name = "msgpack_real_node");
        super.new(name);
        node_type = MSGPACK_NODE_REAL;
    endfunction

    `uvm_object_param_utils(msgpack_real_node)
    `msgpack_node_utils(msgpack_real_node, real)
endclass

class msgpack_bin_node extends msgpack_node#(msgpack_bin);
    function new(string name = "msgpack_bin_node");
        super.new(name);
        node_type = MSGPACK_NODE_BIN;
    endfunction

    `uvm_object_param_utils(msgpack_bin_node)
    `msgpack_node_utils(msgpack_bin_node, msgpack_bin)
endclass

class msgpack_array_node extends msgpack_node_base;
    int unsigned size;

    function new(string name = "msgpack_array_node");
        super.new(name);
        node_type = MSGPACK_NODE_ARRAY;
    endfunction

    function void do_print (uvm_printer printer);
        printer.print_string("size", $sformatf("%0p", size));
        super.do_print(printer);
        foreach(children[i]) begin
            printer.print_object($sformatf("child_%0d", i), children[i]);
        end
    endfunction

    `uvm_object_utils(msgpack_array_node)
endclass

class msgpack_map_node extends msgpack_node_base;
    int unsigned size;
    
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
    protected internal_map#(real) real_map;
    protected internal_map#(string) string_map;
    protected internal_map#(bit) bool_map;
    protected internal_map#(msgpack_node_base) array_map;

    function new(string name = "msgpack_map_node");
        super.new(name);
        node_type = MSGPACK_NODE_MAP;
        int_map = new();
        uint_map = new();
        real_map = new();
        string_map = new();
        bool_map = new();
        array_map = new();
    endfunction

    function void add_key_value(msgpack_node_base key, msgpack_node_base value);
        key.parent = this;
        value.parent = key;
        case(key.node_type) inside
            MSGPACK_NODE_INT: int_map.add_key_value(key, value);
            MSGPACK_NODE_UINT: uint_map.add_key_value(key, value);
            MSGPACK_NODE_REAL: real_map.add_key_value(key, value);
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
            MSGPACK_NODE_REAL: real_map.add_key_value(key, value);
            MSGPACK_NODE_STRING: string_map.add_key_value(key, value);
            MSGPACK_NODE_BOOL: bool_map.add_key_value(key, value);
            MSGPACK_NODE_ARRAY : MSGPACK_NODE_EXT: array_map.add_key_value(key, value);
            default: `uvm_fatal(get_name(), "Unexpected node type")
        endcase
    endfunction;

    function msgpack_node_base get_value(msgpack_node_base key);
        case(key.node_type)
            MSGPACK_NODE_INT: return int_map.get_value(key);
            MSGPACK_NODE_UINT: return uint_map.get_value(key);
            MSGPACK_NODE_REAL: return real_map.get_value(key);
            MSGPACK_NODE_STRING: return string_map.get_value(key);
            MSGPACK_NODE_BOOL: return bool_map.get_value(key);
            MSGPACK_NODE_ARRAY : MSGPACK_NODE_EXT: return array_map.get_value(key);
            default: `uvm_fatal(get_name(), "Unexpected node type")
        endcase
    endfunction

    function void do_print (uvm_printer printer);
        printer.print_string("size", $sformatf("%0p", size));
        super.do_print(printer);
        foreach(int_map.map[i]) begin
            printer.print_string("Key", $sformatf("%h", i));
            printer.print_object("Value ", int_map.map[i]);
        end
        foreach(uint_map.map[i]) begin
            printer.print_string("Key", $sformatf("%h", i));
            printer.print_object("Value", uint_map.map[i]);
        end
        foreach(real_map.map[i]) begin
            printer.print_string("Key", $sformatf("%f", i));
            printer.print_object("Value: ", real_map.map[i]);
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