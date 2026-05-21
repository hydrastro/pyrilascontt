// SPDX-License-Identifier: Apache-2.0
// 5-bit ASCON S-box column.
// Bit order:
//   x_i[0] = ASCON word x0 bit[column]
//   x_i[1] = ASCON word x1 bit[column]
//   x_i[2] = ASCON word x2 bit[column]
//   x_i[3] = ASCON word x3 bit[column]
//   x_i[4] = ASCON word x4 bit[column]

`default_nettype none

module tt_ascon_sbox5 (
  input  wire [4:0] x_i,
  output wire [4:0] x_o
);
  wire x0 = x_i[0];
  wire x1 = x_i[1];
  wire x2 = x_i[2];
  wire x3 = x_i[3];
  wire x4 = x_i[4];

  wire a0 = x0 ^ x4;
  wire a1 = x1;
  wire a2 = x2 ^ x1;
  wire a3 = x3;
  wire a4 = x4 ^ x3;

  wire t0 = (~a0) & a1;
  wire t1 = (~a1) & a2;
  wire t2 = (~a2) & a3;
  wire t3 = (~a3) & a4;
  wire t4 = (~a4) & a0;

  wire b0 = a0 ^ t1;
  wire b1 = a1 ^ t2;
  wire b2 = a2 ^ t3;
  wire b3 = a3 ^ t4;
  wire b4 = a4 ^ t0;

  wire c0 = b0 ^ b4;
  wire c1 = b1 ^ b0;
  wire c2 = ~b2;
  wire c3 = b3 ^ b2;
  wire c4 = b4;

  assign x_o = {c4, c3, c2, c1, c0};

endmodule

`default_nettype wire
