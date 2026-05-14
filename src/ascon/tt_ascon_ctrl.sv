// Generated ASCON control/sequencer skeleton.
// profile=hardcoded_fsm
// area_class=very_low, flexibility=low
// scheduler=fixed_phase_fsm
// microcode_words=0, command_fifo_depth=0, csr_register_count=0
module tt_ascon_ctrl #(
  parameter int MICROCODE_WORDS = 0,
  parameter int COMMAND_FIFO_DEPTH = 0,
  parameter int CSR_REGISTER_COUNT = 0,
  parameter int AXI_STREAM_COMMAND_CHANNELS = 0
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start_i,
  output logic busy_o,
  output logic command_valid_o
);

  // TODO: replace this control scaffold with the selected control backend.
  assign busy_o = start_i;
  assign command_valid_o = start_i;
endmodule
