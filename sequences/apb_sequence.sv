class apb_sequence extends uvm_sequence #(apb_seq_item);
`uvm_object_utils(apb_sequence)

function new(string name="apb_sequence");
	super.new(name);
endfunction

task apb_write(bit [`ADDR_WIDTH-1:0] addr,bit [31:0] data,bit pprot=1,bit cfg=0);
	req=apb_seq_item::type_id::create("req");
	start_item(req);
	if(!req.randomize() with{PWRITE==1;PADDR==addr;PWDATA==data;PPROT[0]==pprot;configure==cfg;})
	`uvm_fatal("SEQ","apb_write randomize failed")
	finish_item(req);
endtask

task apb_read(bit [`ADDR_WIDTH-1:0] addr,bit pprot=1);
	req=apb_seq_item::type_id::create("req");
	start_item(req);
	if(!req.randomize() with{PWRITE==0;PADDR==addr;PPROT[0]==pprot;configure==0;})
	`uvm_fatal("SEQ","apb_read randomize failed")
	finish_item(req);
endtask

task write_key(logic [127:0] key='x,logic pprot=1'b1);
	apb_seq_item k;
	bit fixed;
	bit tempp;
	k=apb_seq_item::type_id::create("k");
	fixed=!$isunknown(key);
	tempp=$isunknown(pprot)?1'b1:pprot;

	if(!k.randomize(whole_key) with{if(fixed)whole_key==key;})
	`uvm_fatal("SEQ","key randomize failed")

	apb_write('h8,k.whole_key[127:96],tempp);
	apb_write('hC,k.whole_key[95:64],tempp);
	apb_write('h10,k.whole_key[63:32],tempp);
	apb_write('h14,k.whole_key[31:0],tempp);
endtask

task write_data(logic [127:0] data='x,logic pprot=1'b1);
	apb_seq_item d;
	bit fixed;
	bit tempp;
	d=apb_seq_item::type_id::create("d");
	fixed=!$isunknown(data);
	tempp=$isunknown(pprot)?1'b1:pprot;

	if(!d.randomize(whole_data) with{if(fixed)whole_data==data;})
	`uvm_fatal("SEQ","data randomize failed")

	apb_write('h18,d.whole_data[127:96],tempp);
	apb_write('h1C,d.whole_data[95:64],tempp);
	apb_write('h20,d.whole_data[63:32],tempp);
	apb_write('h24,d.whole_data[31:0],tempp);
endtask

task read_data(bit pprot=1);
	apb_read('h28,pprot);
	apb_read('h2C,pprot);
	apb_read('h30,pprot);
	apb_read('h34,pprot);
endtask

task configure(bit mode=1,bit start=1,bit key_lock=0,bit zeroize=0,bit pprot=1);
	apb_write('h00,{28'b0,zeroize,key_lock,mode,start},pprot,start);
endtask

task body();
	write_key(128'h2B7E151628AED2A6ABF7158809CF4F3C);
	write_data(128'h6BC1BEE22E409F96E93D7E117393172A);
	configure();
	read_data();
endtask

endclass

class seq1 extends apb_sequence;
`uvm_object_utils(seq1)

function new(string name="seq1");
	super.new(name);
endfunction

task body();
	write_key(128'h2B7E151628AED2A6ABF7158809CF4F3C);
	write_data(128'h6BC1BEE22E409F96E93D7E117393172A);
	configure();
	read_data();
endtask

endclass
