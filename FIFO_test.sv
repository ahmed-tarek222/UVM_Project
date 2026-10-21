package FIFO_test_pkg;
  import uvm_pkg::*;
  import FIFO_config_pkg::*;
  import FIFO_env_pkg::*;
  import FIFO_sequences_pkg::*;
  `include "uvm_macros.svh"

  class FIFO_test extends uvm_test;
    `uvm_component_utils(FIFO_test)

    FIFO_env                 env;
    FIFO_config              FIFO_cfg;
    FIFO_reset_sequence      reset_seq;
    FIFO_write_only_sequence write_only_seq;
    FIFO_read_only_sequence  read_only_seq;
    FIFO_write_read_sequence write_read_seq;
    FIFO_main_sequence       main_seq;

    function new(string name = "FIFO_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env      = FIFO_env::type_id::create("env", this);
      FIFO_cfg = FIFO_config::type_id::create("FIFO_cfg");

      reset_seq      = FIFO_reset_sequence::type_id::create("reset_seq");
      write_only_seq = FIFO_write_only_sequence::type_id::create("write_only_seq");
      read_only_seq  = FIFO_read_only_sequence::type_id::create("read_only_seq");
      write_read_seq = FIFO_write_read_sequence::type_id::create("write_read_seq");
      main_seq       = FIFO_main_sequence::type_id::create("main_seq");

      if (!uvm_config_db #(virtual FIFO_if)::get(this, "", "FIFO_IF", FIFO_cfg.FIFO_vif))
        `uvm_fatal("build_phase", "Test - unable to get the virtual interface of the FIFO from the uvm_config_db")

      FIFO_cfg.is_active = UVM_ACTIVE;
      uvm_config_db #(FIFO_config)::set(this, "*", "CFG", FIFO_cfg);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      phase.raise_objection(this);

      // 1) Reset
      `uvm_info("run_phase", "Reset asserted", UVM_LOW)
      reset_seq.start(env.agt.sqr);
      `uvm_info("run_phase", "Reset deasserted", UVM_LOW)

      // 2) Write only: fill the FIFO and overflow it (FIFO_2..FIFO_4, FIFO_8, FIFO_10)
      `uvm_info("run_phase", "Stimulus generation started: write_only_sequence", UVM_LOW)
      write_only_seq.start(env.agt.sqr);

      // 3) Write + read while FULL: only the read takes place (FIFO_15, FIFO_16)
      `uvm_info("run_phase", "Stimulus generation started: write_read_sequence (FIFO full)", UVM_LOW)
      write_read_seq.start(env.agt.sqr);

      // 4) Read only: drain the FIFO and underflow it (FIFO_6, FIFO_9, FIFO_11, FIFO_19)
      `uvm_info("run_phase", "Stimulus generation started: read_only_sequence", UVM_LOW)
      read_only_seq.start(env.agt.sqr);

      // 5) Write + read while EMPTY: only the write takes place (FIFO_14, FIFO_16)
      `uvm_info("run_phase", "Stimulus generation started: write_read_sequence (FIFO empty)", UVM_LOW)
      write_read_seq.start(env.agt.sqr);

      // 6) Reset in the middle of operation (FIFO_1)
      `uvm_info("run_phase", "Reset asserted while the FIFO is not empty", UVM_LOW)
      reset_seq.start(env.agt.sqr);

      // 7) Randomized main sequence, write biased (wr_en 70%, rd_en 30%)
      `uvm_info("run_phase", "Stimulus generation started: main_sequence (write biased)", UVM_LOW)
      main_seq.start(env.agt.sqr);

      // 8) Randomized main sequence, read biased (wr_en 30%, rd_en 70%)
      `uvm_info("run_phase", "Stimulus generation started: main_sequence (read biased)", UVM_LOW)
      main_seq.num_items     = 1000;
      main_seq.wr_en_on_dist = 30;
      main_seq.rd_en_on_dist = 70;
      main_seq.start(env.agt.sqr);

      `uvm_info("run_phase", "Stimulus generation ended", UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass

endpackage
