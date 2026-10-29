`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_rst)

typedef enum bit [7:0]{
  control_addr   = 8'h00,
  status_addr    = 8'h04,
  key0_addr      = 8'h08,
  key1_addr      = 8'h0c,
  key2_addr      = 8'h10,
  key3_addr      = 8'h14,
  data0_addr     = 8'h18,
  data1_addr     = 8'h1c,
  data2_addr     = 8'h20,
  data3_addr     = 8'h24,
  data_out0_addr = 8'h28,
  data_out1_addr = 8'h2c,
  data_out2_addr = 8'h30,
  data_out3_addr = 8'h34
} reg_addr_e;

typedef enum int{
  start_bit    = 0,
  mode_bit     = 1,
  key_lock_bit = 2,
  zeroize_bit  = 3
} control_bit_e;

class aes128_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(aes128_scoreboard)

  uvm_analysis_imp_apb #(apb_seq_item, aes128_scoreboard) apb_imp;
  uvm_analysis_imp_rst #(bit [1:0], aes128_scoreboard) rst_imp;
  aes128_predictor model;

  localparam int BLOCKS = 1024;

  bit [31:0] key_words [4];
  bit mode;
  bit key_locked;

  bit [31:0] in_words[4];
  bit [3:0]  in_mask;
  bit [127:0] in_blocks[$];

  bit [127:0] expected_q [$];
  bit [3:0]   out_mask;

  bit sec_exp;
  bit started;

  int blocks_in_count;
  int blocks_out_count;
  int error_count;
  int tb_fault_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_imp = new("apb_imp", this);
    rst_imp = new("rst_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    model = aes128_predictor::type_id::create("model", this);
  endfunction

  function bit addr_ok(bit [7:0] a, bit wr); // Address check 
    if (a[1:0] != 2'b00) return 0;
    if (a > 8'h34) return 0;
    if (wr && (a == status_addr || (a >= data_out0_addr && a <= data_out3_addr))) return 0;
    return 1;
  endfunction

  function bit needs_priv(bit [7:0] a); // Check Privilege
    if (a == status_addr) return 0;
    if (a >= data_out0_addr && a <= data_out3_addr) return 0;
    return 1;
  endfunction

  function void write_apb(apb_seq_item t);
    bit ok       = addr_ok(t.PADDR, t.PWRITE);
    bit priv_req = ok && needs_priv(t.PADDR);
    bit priv_bad = priv_req && !t.PPROT[0];
    bit exp_e    = !ok || priv_bad;
    bit sec_prev = sec_exp;

    if (sec_prev && t.SEC_VIOLATION !== 1'b1) begin
      error_count++;
      `uvm_error("SB", "SEC_VIOLATION deasserted before rest")
    end
    if (!sec_prev && !exp_e && t.SEC_VIOLATION === 1'b1) begin
      error_count++;
      `uvm_error("SB", $sformatf("unexpected SEC_VIOLATION addr=%02h", t.PADDR))
    end

    if (t.PSLVERR !== exp_e) begin
      error_count++;
      `uvm_error("SB", $sformatf("PSLVERR mismatch addr=%02h wr=%0b pprot0=%0b exp=%0b act=%0b", t.PADDR, t.PWRITE, t.PPROT[0], exp_e, t.PSLVERR))
    end

    if (exp_e) begin
      sec_exp = 1;
      return;
    end
    if (t.PSLVERR === 1'b1) return;

    if (t.PWRITE) begin
      if (t.PADDR == control_addr)
        write_control(t.PWDATA);
      else if (t.PADDR inside {[key0_addr:key3_addr]})
        write_key((t.PADDR - key0_addr) >> 2, t.PWDATA);
      else if (t.PADDR inside {[data0_addr:data3_addr]})
        write_data((t.PADDR - data0_addr) >> 2, t.PWDATA);
    end
    else begin
      if (t.PADDR == status_addr)
        check_status(t.PRDATA);
      else if (t.PADDR inside {[key0_addr:key3_addr]})
        check_key_read(t.PADDR, t.PRDATA);
      else if (t.PADDR inside {[data_out0_addr:data_out3_addr]})
        read_data_out((t.PADDR - data_out0_addr) >> 2, t.PRDATA);
    end
  endfunction

  function void check_key_read(bit [7:0] a, bit [31:0] word);
    if (word !== 32'h0) begin
      error_count++;
      `uvm_error("SB", $sformatf("key register %02h read returned %08h, expected 0", a, word))
    end
  endfunction

  function void check_status(bit [31:0] v);
    if ($isunknown(v)) begin
      error_count++;
      `uvm_error("SB", $sformatf("STATUS has X/Z value %08h", v))
      return;
    end
    if (v[31:2] != 0) begin
      error_count++;
      `uvm_error("SB", $sformatf("STATUS reserved bits non-zero %08h", v))
    end
    if (v[1] && v[0]) begin
      error_count++;
      `uvm_error("SB", "STATUS BUSY and DONE both set")
    end
    if ((v[1] || v[0]) && !started) begin
      error_count++;
      `uvm_error("SB", $sformatf("STATUS %08h shows activity but no start was issued", v))
    end
  endfunction

  function void write_key(int idx, bit [31:0] word);
    if (!key_locked) key_words[idx] = word;
  endfunction

  function void write_control(bit [31:0] value);
    if (value[zeroize_bit]) zeroize();
    if (!key_locked) mode = value[mode_bit];
    if (value[key_lock_bit]) key_locked = 1;
    if (value[start_bit]) start_batch();
  endfunction

  function void zeroize();
    in_words = '{default: 32'h0};
    in_mask = 0;
    out_mask = 0;
    in_blocks.delete();
    expected_q.delete();
    if (!key_locked) begin
      key_words = '{default: 32'h0};
      mode = 0;
    end
  endfunction

  function bit [127:0] pack_in();
    bit [127:0] b;
    for (int i = 0; i < 4; i++)
      b[127-32*i-:32] = in_mask[i] ? in_words[i] : 32'h0;
    return b;
  endfunction

  function void push_block(bit [127:0] b);
    in_blocks.push_back(b);
    blocks_in_count++;
    in_words = '{default: 32'h0};
    in_mask  = 0;
  endfunction

  function void write_data(int idx, bit [31:0] word);
    if (expected_q.size() != 0) begin
      tb_fault_count++;
      `uvm_warning("SB", "DATA write while previous transaction pending, write discarded")
      return;
    end
    in_words[idx] = word;
    in_mask[idx]  = 1;
    if (in_mask == 4'hf) begin
      if (in_blocks.size() >= BLOCKS) begin
        tb_fault_count++;
        `uvm_warning("SB", $sformatf("more than %0d blocks written, block discarded", BLOCKS))
        in_words = '{default: 32'h0};
        in_mask  = 0;
      end
      else
        push_block(pack_in());
    end 
  endfunction

  function void read_data_out(int idx, bit [31:0] word);
    bit [127:0] exp_blk;
    bit [31:0]  exp_words [4];

    if (expected_q.size() == 0) begin
      error_count++;
      `uvm_error("SB", $sformatf("unexpected DATA_OUT%0d read value %08h", idx, word))
      return;
    end

    exp_blk = expected_q[0];
    {exp_words[0], exp_words[1], exp_words[2], exp_words[3]} = exp_blk;

    if (word !== exp_words[idx]) begin
      error_count++;
      `uvm_error("SB", $sformatf("mismatch block %0d word %0d exp=%08h act=%08h", blocks_out_count, idx, exp_words[idx], word))
    end

    out_mask[idx] = 1;
    if (out_mask == 4'hf) begin
      `uvm_info("SB", $sformatf("block %0d read complete %032h", blocks_out_count, exp_blk), UVM_MEDIUM)
      void'(expected_q.pop_front());
      blocks_out_count++;
      out_mask = 0;
    end
  endfunction

  function void start_batch();
    bit [127:0] key = {key_words[0], key_words[1], key_words[2], key_words[3]};

    if (expected_q.size() != 0) begin
      tb_fault_count++;
      `uvm_warning("SB", "START while previous transaction pending, ignored")
      return;
    end

    if (in_mask != 0) begin
      `uvm_warning("SB", $sformatf("start with partial block, mask=%04b, padding with zeros", in_mask))
      push_block(pack_in());
    end
    else if (in_blocks.size() == 0) begin
      `uvm_warning("SB", "start with no data, processing a zero block")
      push_block(128'h0);
    end

    started = 1;

    foreach (in_blocks[i])
      expected_q.push_back(mode ? model.Encryption(key,in_blocks[i]):model.Decryption(key,in_blocks[i]));
    in_blocks.delete();
  endfunction

  function void write_rst(bit [1:0] r);
    `uvm_info("SB", $sformatf("reset event %02b", r), UVM_MEDIUM)
    if (r[1]) clear_apb_state();
    if (r[0]) clear_crypto_state();
  endfunction

  function void clear_apb_state();
    key_words  = '{default: 32'h0};
    mode       = 0;
    key_locked = 0;
    in_words   = '{default: 32'h0};
    in_mask    = 0;
    in_blocks.delete();
    sec_exp    = 0;
    clear_crypto_state();
  endfunction

  function void clear_crypto_state();
    expected_q.delete();
    out_mask = 0;
    started  = 0;
  endfunction

  function void check_phase(uvm_phase phase);
    if (expected_q.size() != 0)
      `uvm_error("SB", $sformatf("%0d expected block(s) never read back", expected_q.size()))
    if (in_blocks.size() != 0 || in_mask != 0)
      `uvm_error("SB", "input data written but start never issued")
    if (out_mask != 0)
      `uvm_error("SB", $sformatf("partial output block left, mask=%04b", out_mask))
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("blocks_in=%0d blocks_out=%0d errors=%0d tb_faults=%0d", blocks_in_count, blocks_out_count, error_count, tb_fault_count), UVM_LOW)
  endfunction
endclass