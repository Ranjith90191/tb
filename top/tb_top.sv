`timescale 1ns/1ps
import uvm_pkg::*;
import aes128_pkg::*;

module top();
  bit PRESETn;
  bit crypto_rstn;
  bit PCLK;
  bit crypto_clk; 

  // Clock generation
  initial begin
    PCLK       = 0;
    crypto_clk = 0; 
  end

  initial begin
    fork
      forever #5 PCLK= ~PCLK;
      forever #2.5 crypto_clk = ~crypto_clk;
    join_none
  end

  // Interface instantiation
  apb_interface   apb_vif(PCLK,PRESETn);
  reset_interface rst_vif(PRESETn,crypto_rstn);
  
  // DUT instantiation
  DUT DUV(
    .PCLK         (apb_vif.PCLK),
    .PRESETn      (apb_vif.PRESETn),
    .crypto_clk   (crypto_clk),
    .crypto_rstn  (rst_vif.crypto_rstn),
    .PSEL         (apb_vif.PSEL),
    .PENABLE      (apb_vif.PENABLE),
    .PWRITE       (apb_vif.PWRITE),
    .PADDR        (apb_vif.PADDR),
    .PWDATA       (apb_vif.PWDATA),
    .PPROT        (apb_vif.PPROT),
    .PRDATA       (apb_vif.PRDATA),
    .PREADY       (apb_vif.PREADY),
    .PSLVERR      (apb_vif.PSLVERR),
    .SEC_VIOLATION(apb_vif.SEC_VIOLATION)
  );
  
  /*
  bind DUT aes128_assertions assertion(
    .PCLK         (PCLK),
    .PRESETn      (PRESETn),
    .crypto_clk   (crypto_clk),
    .crypto_rstn  (crypto_rstn),
    .PSEL         (PSEL),
    .PENABLE      (PENABLE),
    .PWRITE       (PWRITE),
    .PADDR        (PADDR),
    .PWDATA       (PWDATA),
    .PPROT        (PPROT),
    .PRDATA       (PRDATA),
    .PREADY       (PREADY),
    .PSLVERR      (PSLVERR),
    .SEC_VIOLATION(SEC_VIOLATION)
  );
  */
  
  initial begin
    uvm_config_db#(virtual apb_interface)::set(null,"*","apb_interface",apb_vif);
    uvm_config_db#(virtual reset_interface)::set(null,"*","reset_interface",rst_vif);
    run_test();	
  end
  
endmodule
