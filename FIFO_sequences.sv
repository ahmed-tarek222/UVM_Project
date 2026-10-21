package FIFO_sequences_pkg;
  import uvm_pkg::*;
  import FIFO_seq_item_pkg::*;
  `include "uvm_macros.svh"

  //--------------------------------------------------------------------------
  // Reset sequence: asserts rst_n for num_items clock cycles
  //--------------------------------------------------------------------------
  class FIFO_reset_sequence extends uvm_sequence #(FIFO_seq_item);
    `uvm_object_utils(FIFO_reset_sequence)
    FIFO_seq_item seq_item;
    int num_items = 2;

    function new(string name = "FIFO_reset_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (num_items) begin
        seq_item = FIFO_seq_item::type_id::create("seq_item");
        start_item(seq_item);
        seq_item.rst_n   = 0;
        seq_item.wr_en   = 0;
        seq_item.rd_en   = 0;
        seq_item.data_in = 0;
        finish_item(seq_item);
      end
    endtask
  endclass

  //--------------------------------------------------------------------------
  // Write only sequence: wr_en = 1, rd_en = 0 (fills the FIFO, then overflows)
  //--------------------------------------------------------------------------
  class FIFO_write_only_sequence extends uvm_sequence #(FIFO_seq_item);
    `uvm_object_utils(FIFO_write_only_sequence)
    FIFO_seq_item seq_item;
    int num_items = FIFO_DEPTH + 4;

    function new(string name = "FIFO_write_only_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (num_items) begin
        seq_item = FIFO_seq_item::type_id::create("seq_item");
        start_item(seq_item);
        if (!seq_item.randomize() with {rst_n == 1; wr_en == 1; rd_en == 0;})
          `uvm_error("RAND", "Randomization failed in FIFO_write_only_sequence")
        finish_item(seq_item);
      end
    endtask
  endclass

  //--------------------------------------------------------------------------
  // Read only sequence: wr_en = 0, rd_en = 1 (drains the FIFO, then underflows)
  //--------------------------------------------------------------------------
  class FIFO_read_only_sequence extends uvm_sequence #(FIFO_seq_item);
    `uvm_object_utils(FIFO_read_only_sequence)
    FIFO_seq_item seq_item;
    int num_items = FIFO_DEPTH + 4;

    function new(string name = "FIFO_read_only_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (num_items) begin
        seq_item = FIFO_seq_item::type_id::create("seq_item");
        start_item(seq_item);
        if (!seq_item.randomize() with {rst_n == 1; wr_en == 0; rd_en == 1;})
          `uvm_error("RAND", "Randomization failed in FIFO_read_only_sequence")
        finish_item(seq_item);
      end
    endtask
  endclass

  //--------------------------------------------------------------------------
  // Write-read sequence: wr_en = 1 and rd_en = 1 in the same cycle
  // (result depends on the FIFO state: empty -> write only, full -> read only)
  //--------------------------------------------------------------------------
  class FIFO_write_read_sequence extends uvm_sequence #(FIFO_seq_item);
    `uvm_object_utils(FIFO_write_read_sequence)
    FIFO_seq_item seq_item;
    int num_items = 4;

    function new(string name = "FIFO_write_read_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (num_items) begin
        seq_item = FIFO_seq_item::type_id::create("seq_item");
        start_item(seq_item);
        if (!seq_item.randomize() with {rst_n == 1; wr_en == 1; rd_en == 1;})
          `uvm_error("RAND", "Randomization failed in FIFO_write_read_sequence")
        finish_item(seq_item);
      end
    endtask
  endclass

  //--------------------------------------------------------------------------
  // Main sequence: fully randomized using the item constraints
  // (rst_n 5% low, wr_en 70% high, rd_en 30% high, data_in corner biased)
  //--------------------------------------------------------------------------
  class FIFO_main_sequence extends uvm_sequence #(FIFO_seq_item);
    `uvm_object_utils(FIFO_main_sequence)
    FIFO_seq_item seq_item;
    int num_items     = 2000;
    int wr_en_on_dist = 70;
    int rd_en_on_dist = 30;

    function new(string name = "FIFO_main_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (num_items) begin
        seq_item = FIFO_seq_item::type_id::create("seq_item");
        seq_item.WR_EN_ON_DIST = wr_en_on_dist;
        seq_item.RD_EN_ON_DIST = rd_en_on_dist;
        start_item(seq_item);
        if (!seq_item.randomize())
          `uvm_error("RAND", "Randomization failed in FIFO_main_sequence")
        finish_item(seq_item);
      end
    endtask
  endclass

endpackage
