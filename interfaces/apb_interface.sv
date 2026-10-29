interface apb_interface(input bit PCLK,PRESETn);
  logic [`ADDR_WIDTH-1:0] PADDR;
  logic [`DATA_WIDTH-1:0] PWDATA, PRDATA;
  logic PSEL, PENABLE, PREADY, PSLVERR, SEC_VIOLATION, PWRITE;
  logic [2:0] PPROT;
  
  clocking drv_cb @(posedge PCLK);
 	default input #0 output #0;
 	output PWRITE, PSEL, PENABLE, PADDR, PWDATA, PPROT;
 	input PREADY,PRDATA;
  endclocking

  clocking mon_cb @(posedge PCLK);
 	default input #0 output #0;
 	input PRDATA,PREADY,PSLVERR,SEC_VIOLATION;
 	input PWRITE,PSEL,PENABLE,PADDR,PWDATA,PPROT;
  endclocking
  
  modport DRV(clocking drv_cb, input PRESETn);
  modport MON(clocking mon_cb, input PRESETn);
 
endinterface
 