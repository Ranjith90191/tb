class aes128_env extends uvm_env;
    `uvm_component_utils(aes128_env)

    aes128_config m_config;
    apb_agent a_agent;
    reset_agent rst_agent;
    aes128_scoreboard m_scoreboard;
    //aes128_coverage m_coverage;

    function new(string name="aes128_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db #(aes128_config)::get(this,"","m_config",m_config)) begin
        `uvm_fatal(get_type_name(), "Environment config object is missing")
      end
      uvm_config_db #(uvm_active_passive_enum)::set(this,"rst_agt","is_active",m_config.reset_agent_is_active);
      uvm_config_db #(uvm_active_passive_enum)::set(this,"apb_agt","is_active",m_config.apb_agent_is_active);      
      a_agent = apb_agent::type_id::create("a_agent", this);
      rst_agent = reset_agent::type_id::create("reset_agent", this);
      m_scoreboard = aes128_scoreboard::type_id::create("m_scoreboard", this);
      //m_coverage = aes128_coverage::type_id::create("m_coverage", this);
   
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
      a_agent.mon.mon_port.connect(m_scoreboard.apb_imp);
      //a_agent.mon.mon_port.connect(m_coverage.apb_imp);
      rst_agent.mon.reset_broadcast.connect(m_scoreboard.rst_imp);
      //rst_agent.mon.reset_broadcast.connect(m_coverage.rst_imp);
    endfunction: connect_phase

endclass: aes128_env
