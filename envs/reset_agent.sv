class reset_agent extends uvm_agent;
 `uvm_component_utils(reset_agent)
 reset_driver drv;
 reset_sequencer seqr;
 reset_monitor mon;

 function new(string name ="reset_agent",uvm_component parent);
     super.new(name, parent);
 endfunction

 function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     if (get_is_active() == UVM_ACTIVE) begin
         drv = reset_driver::type_id::create("drv",this);
         seqr =reset_sequencer::type_id::create("seqr",this);
     end
     mon = reset_monitor::type_id::create("mon", this);
 endfunction

 function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
     if (get_is_active() == UVM_ACTIVE)
         drv.seq_item_port.connect(seqr.seq_item_export);
 endfunction
endclass
