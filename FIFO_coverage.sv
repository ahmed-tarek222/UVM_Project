package FIFO_coverage_pkg;
  import uvm_pkg::*;
  import FIFO_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class FIFO_coverage extends uvm_component;
    `uvm_component_utils(FIFO_coverage)

    uvm_analysis_export   #(FIFO_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(FIFO_seq_item) cov_fifo;
    FIFO_seq_item                          seq_item_cov;

    covergroup FIFO_cvr_gp;
      // Control inputs
      cp_wr_en:       coverpoint seq_item_cov.wr_en       {bins low = {0}; bins high = {1};}
      cp_rd_en:       coverpoint seq_item_cov.rd_en       {bins low = {0}; bins high = {1};}

      // Outputs
      cp_full:        coverpoint seq_item_cov.full        {bins low = {0}; bins high = {1};}
      cp_empty:       coverpoint seq_item_cov.empty       {bins low = {0}; bins high = {1};}
      cp_almostfull:  coverpoint seq_item_cov.almostfull  {bins low = {0}; bins high = {1};}
      cp_almostempty: coverpoint seq_item_cov.almostempty {bins low = {0}; bins high = {1};}
      cp_overflow:    coverpoint seq_item_cov.overflow    {bins low = {0}; bins high = {1};}
      cp_underflow:   coverpoint seq_item_cov.underflow   {bins low = {0}; bins high = {1};}
      cp_wr_ack:      coverpoint seq_item_cov.wr_ack      {bins low = {0}; bins high = {1};}

      // Flag transitions (FIFO_22)
      cp_full_trans:        coverpoint seq_item_cov.full        {bins to_full  = (0 => 1); bins from_full  = (1 => 0);}
      cp_empty_trans:       coverpoint seq_item_cov.empty       {bins from_empty = (1 => 0); bins to_empty = (0 => 1);}
      cp_almostfull_trans:  coverpoint seq_item_cov.almostfull  {bins rise = (0 => 1); bins fall = (1 => 0);}
      cp_almostempty_trans: coverpoint seq_item_cov.almostempty {bins rise = (0 => 1); bins fall = (1 => 0);}

      // Data corners on accepted writes (FIFO_19)
      cp_data_in: coverpoint seq_item_cov.data_in iff (seq_item_cov.wr_ack) {
        bins zero     = {16'h0000};
        bins all_ones = {16'hFFFF};
        bins others   = {[16'h0001:16'hFFFE]};
      }

      // Cross coverage of wr_en, rd_en and every output (FIFO_21)
      // Combinations that the specification makes impossible are illegal bins,
      // so hitting them is reported as an error.
      cx_full: cross cp_wr_en, cp_rd_en, cp_full {
        // a read is always accepted when full -> FIFO can not be full right after a read
        illegal_bins rd_full = binsof(cp_rd_en.high) && binsof(cp_full.high);
      }
      cx_empty: cross cp_wr_en, cp_rd_en, cp_empty {
        // a write is always accepted when empty -> FIFO can not be empty right after a write
        illegal_bins wr_empty = binsof(cp_wr_en.high) && binsof(cp_empty.high);
      }
      cx_almostfull:  cross cp_wr_en, cp_rd_en, cp_almostfull;
      cx_almostempty: cross cp_wr_en, cp_rd_en, cp_almostempty;
      cx_overflow: cross cp_wr_en, cp_rd_en, cp_overflow {
        illegal_bins no_wr_overflow = binsof(cp_wr_en.low) && binsof(cp_overflow.high);
      }
      cx_underflow: cross cp_wr_en, cp_rd_en, cp_underflow {
        illegal_bins no_rd_underflow = binsof(cp_rd_en.low) && binsof(cp_underflow.high);
      }
      cx_wr_ack: cross cp_wr_en, cp_rd_en, cp_wr_ack {
        illegal_bins no_wr_ack = binsof(cp_wr_en.low) && binsof(cp_wr_ack.high);
      }
    endgroup

    function new(string name = "FIFO_coverage", uvm_component parent = null);
      super.new(name, parent);
      FIFO_cvr_gp = new();
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cov_export = new("cov_export", this);
      cov_fifo   = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      cov_export.connect(cov_fifo.analysis_export);
    endfunction

    // Coverage is collected only while the FIFO is out of reset
    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        cov_fifo.get(seq_item_cov);
        if (seq_item_cov.rst_n)
          FIFO_cvr_gp.sample();
      end
    endtask
  endclass

endpackage
