////////////////////////////////////////////////////////////////////////////////
// FIFO assertions - bound to every FIFO instance from FIFO_top:
//   bind FIFO FIFO_sva #(...) FIFO_sva_inst (...);
// Every concurrent assertion has a matching cover directive
// (sequential domain coverage).
////////////////////////////////////////////////////////////////////////////////
module FIFO_sva #(parameter FIFO_WIDTH = 16, parameter FIFO_DEPTH = 8) (
  input                               clk, rst_n, wr_en, rd_en,
  input [FIFO_WIDTH-1:0]              data_in, data_out,
  input                               full, empty, almostfull, almostempty,
  input                               wr_ack, overflow, underflow,
  input [$clog2(FIFO_DEPTH)-1:0]      wr_ptr, rd_ptr,
  input [$clog2(FIFO_DEPTH):0]        count
);

  //--------------------------------------------------------------------------
  // FIFO_1 : asynchronous reset (checked immediately, without a clock edge)
  //--------------------------------------------------------------------------
  always_comb begin
    if (!rst_n)
      a_reset: assert final (wr_ptr == 0 && rd_ptr == 0 && count == 0 &&
                             !wr_ack && !overflow && !underflow)
        else $error("FIFO_1: asynchronous reset did not clear pointers/counter/outputs");
  end

  // Default clock and reset for all properties, assertions and cover directives
  default clocking cb @(posedge clk); endclocking
  default disable iff (!rst_n);

  //--------------------------------------------------------------------------
  // Properties
  //--------------------------------------------------------------------------
  // FIFO_2 / FIFO_3 : write acknowledge
  property p_wr_ack;          (wr_en && !full)    |=>  wr_ack;                endproperty
  property p_wr_ack_low;      !(wr_en && !full)   |=> !wr_ack;                endproperty
  // FIFO_4 / FIFO_5 : overflow
  property p_overflow;        (wr_en && full)     |=>  overflow;              endproperty
  property p_overflow_low;    !(wr_en && full)    |=> !overflow;              endproperty
  // FIFO_6 / FIFO_7 : underflow
  property p_underflow;       (rd_en && empty)    |=>  underflow;             endproperty
  property p_underflow_low;   !(rd_en && empty)   |=> !underflow;             endproperty
  // FIFO_8 .. FIFO_12 : status flags
  property p_full;            full        == (count == FIFO_DEPTH);           endproperty
  property p_empty;           empty       == (count == 0);                    endproperty
  property p_almostfull;      almostfull  == (count == FIFO_DEPTH-1);         endproperty
  property p_almostempty;     almostempty == (count == 1);                    endproperty
  property p_full_empty_mutex; !(full && empty);                              endproperty
  // FIFO_13 : counter (write only / read only / idle)
  property p_count_wr;        (wr_en && !rd_en && !full)  |=> (count == $past(count) + 1); endproperty
  property p_count_rd;        (!wr_en && rd_en && !empty) |=> (count == $past(count) - 1); endproperty
  property p_count_idle;      (!wr_en && !rd_en)          |=> $stable(count);              endproperty
  // FIFO_14 / FIFO_15 / FIFO_16 : simultaneous read and write
  property p_count_wr_rd_empty; (wr_en && rd_en && empty)          |=> (count == $past(count) + 1); endproperty
  property p_count_wr_rd_full;  (wr_en && rd_en && full)           |=> (count == $past(count) - 1); endproperty
  property p_count_wr_rd_mid;   (wr_en && rd_en && !full && !empty) |=> $stable(count);             endproperty
  // FIFO_17 : pointers
  property p_wr_ptr_inc;      (wr_en && !full)  |=> (wr_ptr == ($past(wr_ptr) + 1) % FIFO_DEPTH); endproperty
  property p_rd_ptr_inc;      (rd_en && !empty) |=> (rd_ptr == ($past(rd_ptr) + 1) % FIFO_DEPTH); endproperty
  property p_wr_ptr_wrap;     (wr_en && !full  && wr_ptr == FIFO_DEPTH-1) |=> (wr_ptr == 0);     endproperty
  property p_rd_ptr_wrap;     (rd_en && !empty && rd_ptr == FIFO_DEPTH-1) |=> (rd_ptr == 0);     endproperty
  property p_wr_ptr_hold;     !(wr_en && !full)  |=> $stable(wr_ptr);                            endproperty
  property p_rd_ptr_hold;     !(rd_en && !empty) |=> $stable(rd_ptr);                            endproperty
  // FIFO_18 : ranges
  property p_ptr_range;       (wr_ptr < FIFO_DEPTH) && (rd_ptr < FIFO_DEPTH);                    endproperty
  property p_count_range;     count <= FIFO_DEPTH;                                                endproperty
  // FIFO_20 : data_out holds its value when no valid read
  property p_data_out_hold;   !(rd_en && !empty) |=> $stable(data_out);                          endproperty

  //--------------------------------------------------------------------------
  // Assertions
  //--------------------------------------------------------------------------

  ap_wr_ack:            assert property (p_wr_ack)
                        else $error("FIFO_2: wr_ack not asserted after an accepted write");
  ap_wr_ack_low:        assert property (p_wr_ack_low)
                        else $error("FIFO_3: wr_ack asserted although no write was accepted");
  ap_overflow:          assert property (p_overflow)
                        else $error("FIFO_4: overflow not asserted after a write while full");
  ap_overflow_low:      assert property (p_overflow_low)
                        else $error("FIFO_5: overflow asserted without a rejected write");
  ap_underflow:         assert property (p_underflow)
                        else $error("FIFO_6: underflow not asserted after a read while empty");
  ap_underflow_low:     assert property (p_underflow_low)
                        else $error("FIFO_7: underflow asserted without a rejected read");
  ap_full:              assert property (p_full)
                        else $error("FIFO_8: full flag wrong");
  ap_empty:             assert property (p_empty)
                        else $error("FIFO_9: empty flag wrong");
  ap_almostfull:        assert property (p_almostfull)
                        else $error("FIFO_10: almostfull flag wrong");
  ap_almostempty:       assert property (p_almostempty)
                        else $error("FIFO_11: almostempty flag wrong");
  ap_full_empty_mutex:  assert property (p_full_empty_mutex)
                        else $error("FIFO_12: full and empty asserted together");
  ap_count_wr:          assert property (p_count_wr)
                        else $error("FIFO_13: count did not increment on a write");
  ap_count_rd:          assert property (p_count_rd)
                        else $error("FIFO_13: count did not decrement on a read");
  ap_count_idle:        assert property (p_count_idle)
                        else $error("FIFO_13: count changed without a request");
  ap_count_wr_rd_empty: assert property (p_count_wr_rd_empty)
                        else $error("FIFO_14: count did not increment on wr+rd while empty");
  ap_count_wr_rd_full:  assert property (p_count_wr_rd_full)
                        else $error("FIFO_15: count did not decrement on wr+rd while full");
  ap_count_wr_rd_mid:   assert property (p_count_wr_rd_mid)
                        else $error("FIFO_16: count changed on wr+rd while not full/empty");
  ap_wr_ptr_inc:        assert property (p_wr_ptr_inc)
                        else $error("FIFO_17: wr_ptr did not increment");
  ap_rd_ptr_inc:        assert property (p_rd_ptr_inc)
                        else $error("FIFO_17: rd_ptr did not increment");
  ap_wr_ptr_wrap:       assert property (p_wr_ptr_wrap)
                        else $error("FIFO_17: wr_ptr did not wrap to 0");
  ap_rd_ptr_wrap:       assert property (p_rd_ptr_wrap)
                        else $error("FIFO_17: rd_ptr did not wrap to 0");
  ap_wr_ptr_hold:       assert property (p_wr_ptr_hold)
                        else $error("FIFO_17: wr_ptr changed without a write");
  ap_rd_ptr_hold:       assert property (p_rd_ptr_hold)
                        else $error("FIFO_17: rd_ptr changed without a read");
  ap_ptr_range:         assert property (p_ptr_range)
                        else $error("FIFO_18: pointer out of range");
  ap_count_range:       assert property (p_count_range)
                        else $error("FIFO_18: count exceeded FIFO_DEPTH");
  ap_data_out_hold:     assert property (p_data_out_hold)
                        else $error("FIFO_20: data_out changed without a read");

  //--------------------------------------------------------------------------
  // Cover directives (sequential domain coverage)
  //--------------------------------------------------------------------------
  cp_wr_ack:            cover property (p_wr_ack);
  cp_wr_ack_low:        cover property (p_wr_ack_low);
  cp_overflow:          cover property (p_overflow);
  cp_overflow_low:      cover property (p_overflow_low);
  cp_underflow:         cover property (p_underflow);
  cp_underflow_low:     cover property (p_underflow_low);
  cp_full:              cover property (count == FIFO_DEPTH   && full);
  cp_empty:             cover property (count == 0            && empty);
  cp_almostfull:        cover property (count == FIFO_DEPTH-1 && almostfull);
  cp_almostempty:       cover property (count == 1            && almostempty);
  cp_count_wr:          cover property (p_count_wr);
  cp_count_rd:          cover property (p_count_rd);
  cp_count_idle:        cover property (p_count_idle);
  cp_count_wr_rd_empty: cover property (p_count_wr_rd_empty);
  cp_count_wr_rd_full:  cover property (p_count_wr_rd_full);
  cp_count_wr_rd_mid:   cover property (p_count_wr_rd_mid);
  cp_wr_ptr_inc:        cover property (p_wr_ptr_inc);
  cp_rd_ptr_inc:        cover property (p_rd_ptr_inc);
  cp_wr_ptr_wrap:       cover property (p_wr_ptr_wrap);
  cp_rd_ptr_wrap:       cover property (p_rd_ptr_wrap);
  cp_wr_ptr_hold:       cover property (p_wr_ptr_hold);
  cp_rd_ptr_hold:       cover property (p_rd_ptr_hold);
  cp_data_out_hold:     cover property (p_data_out_hold);
  // Fill the FIFO from empty to full and drain it back
  cp_fill_to_full:      cover property (empty ##[1:$] almostfull ##[1:$] full);
  cp_drain_to_empty:    cover property (full  ##[1:$] almostempty ##[1:$] empty);
  cp_overflow_burst:    cover property (overflow [*2]);
  cp_underflow_burst:   cover property (underflow [*2]);

endmodule
