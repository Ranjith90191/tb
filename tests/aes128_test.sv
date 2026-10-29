class aes128_test extends uvm_test;
`uvm_component_utils(aes128_test)
aes128_env env;
aes128_config m_config;
function new(string name="aes128_test",uvm_component parent=null);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	m_config=aes128_config::type_id::create("m_config");
	if(!uvm_config_db#(virtual apb_interface)::get(this,"","apb_interface",m_config.a_vif))
		`uvm_fatal(get_type_name(),"config get failed")
    if(!uvm_config_db#(virtual reset_interface)::get(this,"","reset_interface",m_config.r_vif))
		`uvm_fatal(get_type_name(),"config get failed")
	uvm_config_db #(aes128_config)::set(this,"*","m_config",m_config);
	env=aes128_env::type_id::create("env",this);
endfunction

function void end_of_elaboration_phase(uvm_phase phase);
	super.end_of_elaboration_phase(phase);
	uvm_top.print_topology(); 
endfunction
endclass

class aes128_basic_test extends aes128_test;

`uvm_component_utils(aes128_basic_test)

apb_sequence s1;
reset_sequence r1;
function new(string name="aes128_basic_test",uvm_component parent=null);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
endfunction

task run_phase(uvm_phase phase);
	phase.raise_objection(this);

	s1=seq1::type_id::create("s1");
	r1=reset_sequence::type_id::create("r1");
	`uvm_info(get_type_name(), "TEST started", UVM_NONE)
	fork
	s1.start(env.a_agent.seqr);
	r1.start(env.rst_agent.seqr);
	join
	#100;
	`uvm_info(get_type_name(), "TEST ended", UVM_NONE)
	phase.drop_objection(this);
endtask

endclass
