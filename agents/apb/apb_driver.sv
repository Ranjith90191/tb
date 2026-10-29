class apb_driver extends uvm_driver #(apb_seq_item);
`uvm_component_utils(apb_driver)

virtual apb_interface.DRV vif;
aes128_config m_config;
bit done = 1;

function new(string name = "apb_driver", uvm_component parent);
	super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	if (!uvm_config_db #(aes128_config)::get(this,"","m_config",m_config))
		`uvm_fatal("DRV", "Driver get failed")
	this.vif = m_config.a_vif.DRV;
endfunction

task run_phase(uvm_phase phase);
	reset_signals();
	//wait (vif.PRESETn === 1'b1);
	fork
		drive();
		reset_watcher();
	join_none
endtask

task drive();
	forever begin
		seq_item_port.get_next_item(req);
		done = 0;
		if (!req.configure) begin
			idle();
			setup(req);
			access();
			seq_item_port.item_done();
			done = 1;
		end
		else begin
			drive_done_wait(req);
			seq_item_port.item_done();
			done = 1;
		end
	end
endtask

task reset_signals();
	vif.drv_cb.PSEL    <= 1'b0;
	vif.drv_cb.PENABLE <= 1'b0;
	vif.drv_cb.PWRITE  <= 1'b0;
	vif.drv_cb.PADDR <= 1'b0;
	vif.drv_cb.PWDATA <= 1'b0;
	vif.drv_cb.PPROT <= 1'b0;
endtask

task idle();
	@(vif.drv_cb);
	vif.drv_cb.PSEL <= 1'b0;
	vif.drv_cb.PENABLE <= 1'b0;
	`uvm_info(get_type_name(),"IDLE",UVM_HIGH)
endtask

task setup(apb_seq_item ds);
	@(vif.drv_cb);
	vif.drv_cb.PSEL <= 1'b1;
	vif.drv_cb.PENABLE <= 1'b0;
	vif.drv_cb.PWRITE <= ds.PWRITE;
	vif.drv_cb.PADDR <= ds.PADDR;
	vif.drv_cb.PPROT <= ds.PPROT;
	vif.drv_cb.PWDATA  <= ds.PWRITE ? ds.PWDATA : 32'h0;
	`uvm_info(get_type_name(),"SETUP",UVM_HIGH)
endtask

task access();
	@(vif.drv_cb);
	vif.drv_cb.PSEL <= 1'b1;
	vif.drv_cb.PENABLE <= 1'b1;
	do @(vif.drv_cb);
	while (!vif.drv_cb.PREADY);
	vif.drv_cb.PSEL <= 1'b0;
	vif.drv_cb.PENABLE <= 1'b0;
	`uvm_info(get_type_name(),"ACCESS",UVM_HIGH)
endtask

task drive_done_wait(apb_seq_item t);
	idle();
	setup(t);
	access();
	t.PWRITE=0;
	t.PADDR=4;
	setup(t);
	access();
	while (vif.drv_cb.PRDATA != 32'h1) begin
		setup(t);
		access();
	end
endtask

task reset_watcher();
	forever begin
		@(negedge vif.PRESETn);
		`uvm_info(get_type_name(), "PRESETn asserted", UVM_HIGH)
		disable drive;
		disable drive_done_wait;
		disable idle;
		disable setup;
		disable access;
		reset_signals();
		if (!done) seq_item_port.item_done();
		done = 1;
		@(posedge vif.PRESETn);
		`uvm_info(get_type_name(), "PRESETn Deasserted", UVM_HIGH)
		fork
			drive();
		join_none
	end
endtask

endclass
