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
        enc = msgpack_enc::type_id::create("enc");
        dec = msgpack_dec::type_id::create("dec");
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