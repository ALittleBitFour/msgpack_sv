`ifndef MSGPACK_PKG__SV
`define MSGPACK_PKG__SV

`include "uvm_pkg.sv"
package msgpack_pkg;
    import uvm_pkg::*;
    `include "msgpack_types.sv"
    `include "msgpack_enc.sv"
    `include "msgpack_dec.sv"
endpackage

`endif