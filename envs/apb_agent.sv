class apb_agent extends uvm_agent;
	`uvm_component_utils(apb_agent)
    apb_sequencer seqr;
    apb_driver drv;
    apb_monitor mon;

	function new(string name="apb_agent", uvm_component parent);
	    super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon=apb_monitor::type_id::create("mon",this);
        if(get_is_active()==UVM_ACTIVE) begin
            drv=apb_driver::type_id::create("drv",this);
            seqr=apb_sequencer::type_id::create("seqr",this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active()==UVM_ACTIVE)begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction

endclass

