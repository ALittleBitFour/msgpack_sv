`include "uvm_pkg.sv"

module top;

import uvm_pkg::*;
import msgpack_pkg::*;

function void check_result(msgpack_result_t result);
    case(result)
        MPACK_OK: begin
            `uvm_info("TOP", "Fine", UVM_NONE)
        end
        MPACK_OOB: begin
            `uvm_info("TOP", "OOB", UVM_NONE)
        end
        MPACK_WRONG_TYPE: begin
            `uvm_info("TOP", "Wrong type", UVM_NONE)
        end
    endcase
endfunction

initial begin
    bit bit_value;
    longint int_value;
    real real_value;
    shortreal shortreal_value;
    automatic msgpack_enc enc = new("enc");
    automatic msgpack_dec dec = new("dec");

    $display("Hello world");
    enc.write_bool(1'b1);
    enc.write_bool(1'b0);
    enc.write_int(-100);
    enc.write_int(52);
    enc.write_real(-1.14);
    enc.write_shortreal(-1.14);
    dec.set_buffer(enc.buffer);
    check_result(dec.read_bool(bit_value));
    `uvm_info("TOP", $sformatf("%0d", bit_value), UVM_NONE)
    check_result(dec.read_bool(bit_value));
    `uvm_info("TOP", $sformatf("%0d", bit_value), UVM_NONE)
    check_result(dec.read_int(int_value));
    `uvm_info("TOP", $sformatf("%0d", int_value), UVM_NONE)
    check_result(dec.read_int(int_value));
    `uvm_info("TOP", $sformatf("%0d", int_value), UVM_NONE)
    check_result(dec.read_real(real_value));
    `uvm_info("TOP", $sformatf("%0f", real_value), UVM_NONE)
    check_result(dec.read_shortreal(shortreal_value));
    `uvm_info("TOP", $sformatf("%0f", shortreal_value), UVM_NONE)
end

endmodule