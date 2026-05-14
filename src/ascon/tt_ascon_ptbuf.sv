// Generated ASCON decrypt plaintext release buffer skeleton.
// Decryption plaintext must not be externally released until tag verification succeeds.
// storage=sram_fifo, capacity_bytes=4096
module tt_ascon_ptbuf #(
  parameter int DATA_BUS_BITS = 16,
  parameter int CAPACITY_BYTES = 4096
) (
  input  logic clk,
  input  logic rst_n,
  input  logic plaintext_valid_i,
  input  logic [DATA_BUS_BITS-1:0] plaintext_i,
  input  logic tag_verified_i,
  input  logic decrypt_failed_i,
  output logic plaintext_valid_o,
  output logic [DATA_BUS_BITS-1:0] plaintext_o
);

  // TODO: implement full-message FIFO/RAM buffering.
  // Until tag_verified_i is asserted, plaintext_valid_o must remain deasserted.
  assign plaintext_valid_o = plaintext_valid_i & tag_verified_i & ~decrypt_failed_i;
  assign plaintext_o = tag_verified_i ? plaintext_i : '0;
endmodule
