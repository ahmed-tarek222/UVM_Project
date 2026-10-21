package FIFO_seq_item_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  parameter FIFO_WIDTH = 16;
  parameter FIFO_DEPTH = 8;

  class FIFO_seq_item extends uvm_sequence_item;
    `uvm_object_utils(FIFO_seq_item)

    // Stimulus (driven)
    rand bit                  rst_n;
    rand bit                  wr_en;
    rand bit                  rd_en;
    rand bit [FIFO_WIDTH-1:0] data_in;

    // Response (monitored)
    logic [FIFO_WIDTH-1:0]    data_out;
    logic                     full, empty, almostfull, almostempty;
    logic                     wr_ack, overflow, underflow;

    // Distribution knobs
    int RD_EN_ON_DIST = 30;
    int WR_EN_ON_DIST = 70;

    function new(string name = "FIFO_seq_item");
      super.new(name);
    endfunction

    // Reset is asserted rarely (5%)
    constraint c_rst_n {
      rst_n dist {1'b0 := 5, 1'b1 := 95};
    }

    // wr_en is high WR_EN_ON_DIST % of the time
    constraint c_wr_en {
      wr_en dist {1'b1 := WR_EN_ON_DIST, 1'b0 := (100 - WR_EN_ON_DIST)};
    }

    // rd_en is high RD_EN_ON_DIST % of the time
    constraint c_rd_en {
      rd_en dist {1'b1 := RD_EN_ON_DIST, 1'b0 := (100 - RD_EN_ON_DIST)};
    }

    // Bias data_in towards the corner values
    constraint c_data_in {
      data_in dist {16'h0000 := 10, 16'hFFFF := 10, [16'h0001:16'hFFFE] :/ 80};
    }

    function string convert2string_stimulus();
      return $sformatf("rst_n=%0b wr_en=%0b rd_en=%0b data_in=%0h", rst_n, wr_en, rd_en, data_in);
    endfunction

    function string convert2string();
      return $sformatf("%s | data_out=%0h full=%0b empty=%0b almostfull=%0b almostempty=%0b wr_ack=%0b overflow=%0b underflow=%0b",
                       convert2string_stimulus(), data_out, full, empty, almostfull, almostempty,
                       wr_ack, overflow, underflow);
    endfunction
  endclass

endpackage
