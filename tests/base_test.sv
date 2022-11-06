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

`ifndef BASE_TEST__SV
`define BASE_TEST__SV

`define check_decoding(VAL, FUNC, EXP, FORMAT) \
begin\
automatic VAL act_value = FUNC();\
check_result(dec.last_result);\
if(act_value != VAL'(EXP)) begin\
    automatic string format_str = `"FORMAT`"; \
    automatic string type_str = `"VAL`"; \
    `uvm_error("TOP", $sformatf({"Type: %s. Actual: ", format_str, " Expected: ", format_str}, type_str, act_value, EXP))\
end\
end

class base_test extends uvm_test;

    msgpack_enc enc;
    msgpack_dec dec;

    function new(string name = "base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        enc = new("enc");
        dec = new("dec");
    endfunction

    function void check_result(msgpack_result_t result);
        case(result)
            MSGPACK_OK: begin
                `uvm_info("TOP", "Fine", UVM_DEBUG)
            end
            MSGPACK_OOB: begin
                `uvm_info("TOP", "OOB", UVM_DEBUG)
            end
            MSGPACK_WRONG_TYPE: begin
                `uvm_info("TOP", "Wrong type", UVM_DEBUG)
            end
        endcase
    endfunction

    function void print_buffer(msgpack_enc enc);
        msgpack_buffer buffer = enc.get_buffer();
        string str;
        foreach(buffer[i]) begin
            str = $sformatf("%s %h", str, buffer[i]);
        end
        `uvm_info("TOP", str, UVM_NONE)
    endfunction

    `uvm_component_utils(base_test)
endclass: base_test

`endif