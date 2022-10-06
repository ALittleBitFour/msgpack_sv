import uvm_pkg::*;
import tests_pkg::*;

module top;

initial begin
    run_test();
end
// initial begin
//     automatic msgpack_bin bin_data = '{1<<16{5}};
//     automatic msgpack_enc enc = new("enc");
//     automatic msgpack_dec dec = new("dec");

//     // `check_decoding(string, dec.read_string, {1<<8{"b"}}, %s);
//     // `check_decoding(string, dec.read_string, {1<<16{"c"}}, %s);
//     // `check_decoding(msgpack_bin, dec.read_bin, bin_data, %p);
// end

endmodule