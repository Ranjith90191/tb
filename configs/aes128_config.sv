class aes128_config extends uvm_object;
    `uvm_object_utils(aes128_config)

    uvm_active_passive_enum reset_agent_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_agent_is_active = UVM_ACTIVE;
    
    virtual apb_interface a_vif;
    virtual reset_interface r_vif;

    function new(string name="apb_agent_config");
        super.new(name);
    endfunction

endclass