class apb_seq_item extends uvm_sequence_item;
rand bit PSEL;
rand bit PENABLE;
rand bit PWRITE;
rand bit [`ADDR_WIDTH-1:0]PADDR;
rand bit [`DATA_WIDTH-1:0]PWDATA;
rand bit [2:0]PPROT; 
bit [`DATA_WIDTH-1:0]PRDATA;
bit PREADY;
bit PSLVERR;
bit SEC_VIOLATION;

rand bit [127:0]whole_key;
rand bit [127:0]whole_data;
rand bit [2:0]pprot;
rand bit configure;

constraint byte_align{
soft PADDR[1:0]==2'b00;
}

constraint addr_range{
soft PADDR<='h34;
}

constraint priority_value{
if (PADDR inside {'h04,'h28,'h2C,'h30,'h34}){
soft PPROT[0]==1'b0;
} 
else{
soft PPROT[0]==1'b1;
}
}

`uvm_object_utils_begin(apb_seq_item)
`uvm_field_int(PSEL,UVM_ALL_ON)
`uvm_field_int(PENABLE,UVM_ALL_ON)
`uvm_field_int(PADDR,UVM_ALL_ON)
`uvm_field_int(PWDATA,UVM_ALL_ON)
`uvm_field_int(PPROT,UVM_ALL_ON)
`uvm_field_int(PRDATA,UVM_ALL_ON)
`uvm_field_int(PREADY,UVM_ALL_ON)
`uvm_field_int(PSLVERR,UVM_ALL_ON)
`uvm_field_int(SEC_VIOLATION,UVM_ALL_ON)
`uvm_field_int(PWRITE,UVM_ALL_ON)
`uvm_field_int(whole_key,UVM_ALL_ON)
`uvm_field_int(whole_data,UVM_ALL_ON)
`uvm_field_int(configure,UVM_ALL_ON)
`uvm_object_utils_end

function new(string name="apb_seq_item");
super.new(name);
endfunction

endclass
