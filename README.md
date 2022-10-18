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