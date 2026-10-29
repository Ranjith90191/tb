class apb_monitor extends uvm_monitor;
	`uvm_component_utils(apb_monitor)
virtual apb_interface.MON vif;
aes128_config m_config;
	uvm_analysis_port #(apb_seq_item) mon_port;

	function new(string name="apb_monitor", uvm_component parent);
	super.new(name,parent);
	mon_port=new("mon_port",this);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(aes128_config)::get(this,"","m_config",m_config))
	`uvm_fatal("MON","Monitor get failed")
	this.vif=m_config.a_vif;
endfunction

task run_phase(uvm_phase phase);
	fork 
		reset_watcher();
		monitor_pins();
	join_none
endtask

	task reset_watcher();
		forever begin
		@(negedge vif.PRESETn);
		`uvm_info(get_type_name(),"RESET DETECTED",UVM_HIGH)
			disable monitor_pins;
		@(posedge vif.PRESETn);
			`uvm_info(get_type_name(),"RESET DEASSERTED",UVM_HIGH)
			fork 
				monitor_pins();
			join_none
		end
	endtask

	task monitor_pins();
		apb_seq_item ms;
		forever begin
			@(vif.mon_cb);
			if(vif.mon_cb.PSEL ==1 && vif.mon_cb.PENABLE ==1 && vif.mon_cb.PREADY==1) begin
				ms=apb_seq_item::type_id::create("ms");
				ms.PWRITE=vif.mon_cb.PWRITE;
				ms.PADDR= vif.mon_cb.PADDR;
				ms.PWDATA=vif.mon_cb.PWDATA;
				ms.PRDATA= vif.mon_cb.PRDATA;
				ms.PSLVERR=vif.mon_cb.PSLVERR;
				ms.SEC_VIOLATION=vif.mon_cb.SEC_VIOLATION;
				ms.PPROT=vif.mon_cb.PPROT; 
				ms.PREADY=1;
	          	mon_port.write(ms);
	        end
		end
	endtask
	
endclass