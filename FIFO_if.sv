interface FIFO_if #(parameter FIFO_WIDTH = 16) (input bit clk);

  logic                  rst_n;
  logic                  wr_en;
  logic                  rd_en;
  logic [FIFO_WIDTH-1:0] data_in;
  logic [FIFO_WIDTH-1:0] data_out;
  logic                  full;
  logic                  empty;
  logic                  almostfull;
  logic                  almostempty;
  logic                  overflow;
  logic                  underflow;
  logic                  wr_ack;

  // The monitor samples at the negative edge, one time step before the edge (#1step),
  // so it always sees the inputs driven at the previous negedge together with the
  // outputs produced by the positive edge in between (race free with the driver).
  clocking mon_cb @(negedge clk);
    default input #1step;
    input rst_n, wr_en, rd_en, data_in,
          data_out, full, empty, almostfull, almostempty, overflow, underflow, wr_ack;
  endclocking

  modport DUT (
    input  clk, rst_n, wr_en, rd_en, data_in,
    output data_out, full, empty, almostfull, almostempty, overflow, underflow, wr_ack
  );

  modport TB (
    input  clk, data_out, full, empty, almostfull, almostempty, overflow, underflow, wr_ack,
    output rst_n, wr_en, rd_en, data_in
  );

  modport MONITOR (clocking mon_cb, input clk);

endinterface
