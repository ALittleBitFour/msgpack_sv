# MessagePack for SystemVerilog

MsgPack_SV is a UVM compatible SystemVerilog implementation of an encoder and decoder for the [MessagePack](https://msgpack.org) serialization format.

MsgPack_SV provides a buffered reader and writer and a parser, that decodes/encodes message into a set of dynamically typed nodes.

# Why Not JSON?

MessagePack and JSON have quite simillar structure, hovewer MessagePack has several improvements:

 * Better support of compound data types. Decoder doesn't need to parse huge part of message to find a size.
 * No need to use escape symbols in strings.
 * Support of binary data type.
 * Extensions can be used to add new data types.
 * Efficient number types.

One of the most important drawback of MessagePack is the unreadable format, hovewer, it MessagePack can be easily converted to JSON and vice versa.

# Examples

## Node API

```verilog
msgpack_tree tree = new();
msgpack_map_node map = new();
msgpack_array_node array = new();

map.add_key_value(msgpack_string_node::create_node("New entry"), msgpack_int_node::create_node(15));
map.add_key_value(msgpack_string_node::create_node("New-new entry"), msgpack_string_node::create_node("Here we go again"));
array.push(msgpack_bool_node::create_node(1'b1));
array.push(msgpack_string_node::create_node("Item"));
array.push(msgpack_int_node::create_node(-15));
map.add_key_value(msgpack_int_node::create_node(100500), array);
    
tree.root = map;
tree.build_msg();
```


## Direct Encode/Decode API

```verilog
msgpack_enc encoder;
msgpack_dec decoder;

encoder.write_map(1);
encoder.write_array(6);
encoder.write_bool(1'b1);
encoder.write_bool(1'b0);
encoder.write_int(-100);
encoder.write_int(52);
encoder.write_real(-1.14);
encoder.write_shortreal(-1.15);
encoder.write_map(2);
encoder.write_string("Hola Comrade!");
encoder.write_int(1000);
encoder.write_string("Hello");
encoder.write_array_begin();
encoder.write_string({100{"a"}});
encoder.write_array_end();

decoder.set_buffer(encoder.get_buffer());
```