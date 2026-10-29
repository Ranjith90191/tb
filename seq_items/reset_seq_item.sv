class reset_seq_item extends uvm_sequence_item;
    `uvm_object_utils(reset_seq_item)

    rand bit idle;
    rand bit duration;
    rand bit [1:0] r_type;
    rand bit [2:0] c_duration; 
    rand bit [2:0] p_duration;

    constraint c_valid {
        r_type inside {[1:3]};
        c_duration > 0;
        p_duration > 0;
    }

    function new(string name="reset_seq_item");
        super.new(name);
    endfunction
endclass

