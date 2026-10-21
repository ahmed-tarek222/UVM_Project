package FIFO_scoreboard_pkg;
  import uvm_pkg::*;
  import FIFO_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class FIFO_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(FIFO_scoreboard)

    uvm_analysis_export   #(FIFO_seq_item) sb_export;
    uvm_tlm_analysis_fifo #(FIFO_seq_item) sb_fifo;
    FIFO_seq_item                          seq_item_sb;

    // Reference model state
    localparam max_fifo_addr = $clog2(FIFO_DEPTH);
    bit   [FIFO_WIDTH-1:0]    mem_ref [FIFO_DEPTH];
    bit   [max_fifo_addr-1:0] wr_ptr_ref, rd_ptr_ref;
    int                       count_ref;

    // Expected outputs
    logic [FIFO_WIDTH-1:0] data_out_ref;
    logic full_ref, empty_ref, almostfull_ref, almostempty_ref;
    logic wr_ack_ref, overflow_ref, underflow_ref;

    int error_count   = 0;
    int correct_count = 0;

    function new(string name = "FIFO_scoreboard", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sb_export = new("sb_export", this);
      sb_fifo   = new("sb_fifo", this);
      wr_ptr_ref   = 0;
      rd_ptr_ref   = 0;
      count_ref    = 0;
      data_out_ref = 'x;
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      sb_export.connect(sb_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        sb_fifo.get(seq_item_sb);
        reference_model(seq_item_sb);
        check_data(seq_item_sb);
      end
    endtask

    // Golden model written from the specification (not from the RTL)
    function void reference_model(FIFO_seq_item item);
      bit wr_ok, rd_ok;

      if (!item.rst_n) begin
        wr_ptr_ref    = 0;
        rd_ptr_ref    = 0;
        count_ref     = 0;
        wr_ack_ref    = 0;
        overflow_ref  = 0;
        underflow_ref = 0;
        // data_out keeps its last value during reset
      end
      else begin
        // When full only the read can take place, when empty only the write
        wr_ok = item.wr_en && (count_ref < FIFO_DEPTH);
        rd_ok = item.rd_en && (count_ref != 0);

        if (wr_ok) begin
          mem_ref[wr_ptr_ref] = item.data_in;
          wr_ptr_ref          = wr_ptr_ref + 1;
        end
        wr_ack_ref   = wr_ok;
        overflow_ref = item.wr_en && (count_ref == FIFO_DEPTH);

        if (rd_ok) begin
          data_out_ref = mem_ref[rd_ptr_ref];
          rd_ptr_ref   = rd_ptr_ref + 1;
        end
        underflow_ref = item.rd_en && (count_ref == 0);

        count_ref = count_ref + wr_ok - rd_ok;
      end

      full_ref        = (count_ref == FIFO_DEPTH);
      empty_ref       = (count_ref == 0);
      almostfull_ref  = (count_ref == FIFO_DEPTH-1);
      almostempty_ref = (count_ref == 1);
    endfunction

    function void check_data(FIFO_seq_item item);
      if (item.data_out    !== data_out_ref    || item.full        !== full_ref        ||
          item.empty       !== empty_ref       || item.almostfull  !== almostfull_ref  ||
          item.almostempty !== almostempty_ref || item.wr_ack      !== wr_ack_ref      ||
          item.overflow    !== overflow_ref    || item.underflow   !== underflow_ref) begin
        error_count++;
        `uvm_error("run_phase", $sformatf({"Comparison failed: %s\n  expected: data_out=%0h full=%0b empty=%0b ",
                   "almostfull=%0b almostempty=%0b wr_ack=%0b overflow=%0b underflow=%0b"},
                   item.convert2string(), data_out_ref, full_ref, empty_ref, almostfull_ref,
                   almostempty_ref, wr_ack_ref, overflow_ref, underflow_ref))
      end
      else begin
        correct_count++;
        `uvm_info("run_phase", $sformatf("Correct FIFO output: %s", item.convert2string()), UVM_HIGH)
      end
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("report_phase", $sformatf("Total successful transactions: %0d", correct_count), UVM_MEDIUM)
      `uvm_info("report_phase", $sformatf("Total failed transactions: %0d", error_count), UVM_MEDIUM)
    endfunction
  endclass

endpackage
