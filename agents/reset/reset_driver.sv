class reset_driver extends uvm_driver #(reset_seq_item);
 `uvm_component_utils(reset_driver)
 virtual reset_interface vif;
 aes128_config m_config;

 function new(string name="reset_driver",uvm_component parent);
     super.new(name,parent);
 endfunction

 function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     if(!uvm_config_db#(aes128_config)::get(this,"","m_config",m_config))
        `uvm_fatal(get_type_name(),"config get failed")
     this.vif=m_config.r_vif;
 endfunction

 task run_phase(uvm_phase phase);
    vif.PRESETn <= 1;
    vif.crypto_rstn <= 1;
    forever begin
        seq_item_port.get_next_item(req);
        if(req.idle)begin
            vif.PRESETn <= 1;
            vif.crypto_rstn <= 1;
            @(posedge vif.PCLK); 
        end
        else begin
            case(req.r_type)
                2'b11:begin
                    vif.PRESETn <= 0;
                    vif.crypto_rstn <= 0;
                    fork
                        begin
                            repeat(req.p_duration)@(posedge vif.PCLK);
                            vif.PRESETn <= 1;
                        end
                        begin
                            repeat(req.c_duration)@(posedge vif.crypto_clk);
                            vif.crypto_rstn <= 1;
                        end
                    join
                end
                2'b01:begin
                    vif.PRESETn <= 1;
                    vif.crypto_rstn <= 0;
                    repeat(req.c_duration)@(posedge vif.crypto_clk);
                    vif.crypto_rstn <= 1;
                end
                2'b10:begin 
                    vif.PRESETn <= 0;
                    vif.crypto_rstn <= 1;
                    repeat (req.p_duration) @(posedge vif.PCLK);
                    vif.PRESETn <= 1;
                end
                default:`uvm_warning(get_type_name(), "No type sorry")
            endcase
        end
        seq_item_port.item_done();
    end
  endtask
endclass

