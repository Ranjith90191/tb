class apb_sequencer extends uvm_sequencer #(apb_seq_item);

    // Factory registration
    `uvm_component_utils(apb_sequencer)

    // Class constructor
    function new(string name="apb_sequencer", uvm_component parent=null);
        super.new(name, parent);
    endfunction

endclass: apb_sequencer