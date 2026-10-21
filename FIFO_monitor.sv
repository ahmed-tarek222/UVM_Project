package FIFO_monitor_pkg;
  import uvm_pkg::*;
  import FIFO_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class FIFO_monitor extends uvm_monitor;
    `uvm_component_utils(FIFO_monitor)

    virtual FIFO_if                    FIFO_vif;
    FIFO_seq_item                      rsp_seq_item;
    uvm_analysis_port #(FIFO_seq_item) mon_ap;

    function new(string name = "FIFO_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon_ap = new("mon_ap", this);
    endfunction

    // Sample every negative edge through the clocking block: one transaction holds
    // the inputs applied at the last positive edge and the outputs they produced.
    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        rsp_seq_item = FIFO_seq_item::type_id::create("rsp_seq_item");
        @(FIFO_vif.mon_cb);
        rsp_seq_item.rst_n       = FIFO_vif.mon_cb.rst_n;
        rsp_seq_item.wr_en       = FIFO_vif.mon_cb.wr_en;
        rsp_seq_item.rd_en       = FIFO_vif.mon_cb.rd_en;
        rsp_seq_item.data_in     = FIFO_vif.mon_cb.data_in;
        rsp_seq_item.data_out    = FIFO_vif.mon_cb.data_out;
        rsp_seq_item.full        = FIFO_vif.mon_cb.full;
        rsp_seq_item.empty       = FIFO_vif.mon_cb.empty;
        rsp_seq_item.almostfull  = FIFO_vif.mon_cb.almostfull;
        rsp_seq_item.almostempty = FIFO_vif.mon_cb.almostempty;
        rsp_seq_item.wr_ack      = FIFO_vif.mon_cb.wr_ack;
        rsp_seq_item.overflow    = FIFO_vif.mon_cb.overflow;
        rsp_seq_item.underflow   = FIFO_vif.mon_cb.underflow;
        mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_HIGH)
      end
    endtask
  endclass

endpackage
