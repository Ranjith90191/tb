class reset_sequence extends uvm_sequence #(reset_seq_item);
    `uvm_object_utils(reset_sequence)

    function new(string name="reset_sequence");
        super.new(name);
    endfunction

    task body();
        req = reset_seq_item::type_id::create("req");
        start_item(req);
        `uvm_info(get_type_name(), "seq started", UVM_NONE)
            if(!req.randomize() with {idle==0;})begin
                `uvm_fatal(get_type_name(),"Randomization failed")
            end
        finish_item(req);
        `uvm_info(get_type_name(), "seq ended", UVM_NONE)
    endtask

endclass