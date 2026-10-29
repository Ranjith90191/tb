class reset_monitor extends uvm_monitor;
    `uvm_component_utils(reset_monitor)

    uvm_analysis_port #(bit [1:0]) reset_broadcast;
    virtual reset_interface vif;
    
    function new(string name ="reset_monitor",uvm_component parent);
        super.new(name, parent);
        reset_broadcast = new("reset_broadcast", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual reset_interface)::get(this,"","reset_interface",vif))
            `uvm_fatal(get_type_name(),"reset_interface get failed")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            watch_crypto_rstn();
            watch_PRESETn();
        join_none
    endtask

    task watch_PRESETn();
        forever begin
            @(negedge vif.PRESETn);
            `uvm_info(get_type_name(),"PRESETn Asserted", UVM_HIGH)
            @(posedge vif.PRESETn);
            `uvm_info(get_type_name(),"PRESETn Deasserted", UVM_HIGH)
            reset_broadcast.write(2'b10);
        end
    endtask

    task watch_crypto_rstn();
        forever begin
            @(negedge vif.crypto_rstn);
            `uvm_info(get_type_name(),"crypto_rstn Asserted", UVM_HIGH)
            @(posedge vif.crypto_rstn);
            `uvm_info(get_type_name(),"crypto_rstn Deasserted", UVM_HIGH)
            reset_broadcast.write(2'b01);
        end
    endtask
endclass

