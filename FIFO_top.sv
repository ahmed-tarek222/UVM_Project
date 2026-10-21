import uvm_pkg::*;
import FIFO_test_pkg::*;
`include "uvm_macros.svh"

module FIFO_top();

  bit clk;

  // Clock generation (period = 10 ns)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  FIFO_if #(.FIFO_WIDTH(16)) FIFOif (clk);

  FIFO #(.FIFO_WIDTH(16), .FIFO_DEPTH(8)) DUT (
    .data_in    (FIFOif.data_in),
    .wr_en      (FIFOif.wr_en),
    .rd_en      (FIFOif.rd_en),
    .clk        (clk),
    .rst_n      (FIFOif.rst_n),
    .full       (FIFOif.full),
    .empty      (FIFOif.empty),
    .almostfull (FIFOif.almostfull),
    .almostempty(FIFOif.almostempty),
    .wr_ack     (FIFOif.wr_ack),
    .overflow   (FIFOif.overflow),
    .underflow  (FIFOif.underflow),
    .data_out   (FIFOif.data_out)
  );

  // Assertions are bound to the FIFO (they can see the internal pointers and counter)
  bind FIFO FIFO_sva #(.FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) FIFO_sva_inst (
    .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
    .data_in(data_in), .data_out(data_out),
    .full(full), .empty(empty), .almostfull(almostfull), .almostempty(almostempty),
    .wr_ack(wr_ack), .overflow(overflow), .underflow(underflow),
    .wr_ptr(wr_ptr), .rd_ptr(rd_ptr), .count(count)
  );

  initial begin
    uvm_config_db #(virtual FIFO_if)::set(null, "uvm_test_top", "FIFO_IF", FIFOif);
    run_test("FIFO_test");
  end

endmodule
