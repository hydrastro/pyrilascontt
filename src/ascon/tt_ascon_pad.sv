// SPDX-License-Identifier: Apache-2.0
// ASCON byte padding helper for byte-stream FSM.
// For the real core, padding is applied by XORing 0x80 at the final byte position.

module tt_ascon_pad (
  input  logic [7:0] byte_i,
  input  logic       final_i,
  output logic [7:0] byte_o
);
  assign byte_o = final_i ? (byte_i ^ 8'h80) : byte_i;
endmodule
