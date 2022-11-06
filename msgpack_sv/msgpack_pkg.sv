/*
Copyright 2022 Ivan Larkou

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is furnished 
to do so, subject to the followigit remote add origin https://github.com/ALittleBitFour/msgpack_sv.gitng conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

`ifndef MSGPACK_PKG__SV
`define MSGPACK_PKG__SV

`ifdef MSGPACK_UVM_SUPPORT
`include "uvm_pkg.sv"
`endif

package msgpack_pkg;
    `ifdef MSGPACK_UVM_SUPPORT
    import uvm_pkg::*;
    `endif
    `include "msgpack_types.sv"
    `include "msgpack_enc.sv"
    `include "msgpack_dec.sv"
    `include "msgpack_node.sv"
    `include "msgpack_tree.sv"
endpackage

/* Package: msgpack_pkg

MessagePack for SystemVerilog:

MsgPack_SV is a UVM compatible SystemVerilog implementation of an encoder and decoder for the [MessagePack](https://msgpack.org) serialization format.

MsgPack_SV provides a buffered reader and writer and a parser, that decodes/encodes message into a set of dynamically typed nodes.

There are two different API: Node API and Direct Write/Read API

Why Not JSON?::

MessagePack and JSON have quite simillar structure, hovewer MessagePack has several improvements:

 * Better support of compound data types. Decoder doesn't need to parse huge part of message to find a size.
 * No need to use escape symbols in strings.
 * Support of binary data type.
 * Extensions can be used to add new data types.
 * Efficient number types.

One of the most important drawback of MessagePack is the unreadable format, hovewer, it MessagePack can be easily converted to JSON and vice versa.

Examples:

*Node API*

---verilog
msgpack_tree tree = new();
msgpack_map_node map = new();
msgpack_array_node array = new();

// Add data to map node
map.add_key_value(msgpack_string_node::create_node("New entry"), 
                  msgpack_int_node::create_node(15));
map.add_key_value(msgpack_string_node::create_node("New-new entry"), 
                  msgpack_string_node::create_node("Here we go again"));

// Push some data to array
array.push(msgpack_bool_node::create_node(1'b1));
array.push(msgpack_string_node::create_node("Item"));
array.push(msgpack_int_node::create_node(-15));
map.add_key_value(msgpack_int_node::create_node(100500), array);

// Build message
tree.root = map;
tree.build_msg();
---

Representation of the resulted message in JSON:

--- Code
{
  "New entry": 15,
  "New-new entry": "Here we go again",
  "100500": [
    true,
    "Item",
    -15
  ]
}
---

See Also: <msgpack_tree>, <msgpack_node>, <msgpack_array_node>, <msgpack_map_node>

*Direct Encode/Decode API*

---verilog
msgpack_enc encoder = new();
msgpack_dec decoder = new();

encoder.write_map(1);       // we can directly set size of map. 
                            // In this case we don't need to
                            // call _end() function

// Add array as a map key
encoder.write_array(6);
encoder.write_bool(1'b1);
encoder.write_bool(1'b0);
encoder.write_int(-100);
encoder.write_int(52);
encoder.write_real(-1.14);
encoder.write_shortreal(-1.15);

// Add map as a map value
encoder.write_map(2);
encoder.write_string("Test");
encoder.write_int(1000);
encoder.write_string("Hello");

encoder.write_array_begin();      // if we want to calculate array/map size automaticaly,
encoder.write_string({10{"a"}});  // we can use _begin() _end() functions
encoder.write_array_end();

decoder.set_buffer(encoder.get_buffer());
---

Representation of the resulted message in JSON:

---Code
{
  "[true,false,-100,52,-1.14,-1.15]": {
    "Test": 1000,
    "Hello": [
      "aaaaaaaaaa"
    ]
  }
}
---

See Also: <msgpack_enc>, <msgpack_dec>

*/ 

`endif