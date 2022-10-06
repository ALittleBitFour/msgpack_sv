`ifndef TESTS_PKG__SV
`define TESTS_PKG__SV

`include "uvm_pkg.sv"
package tests_pkg;
    import uvm_pkg::*;
    import msgpack_pkg::*;

    `include "base_test.sv"
    `include "direct_set_test.sv"
    `include "big_string_test.sv"
endpackage

`endif