/*
 * Copyright (c) 2026 hydrastro
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_hydrastro_pyrilascon (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire [7:0] data_i;
  wire [3:0] cmd_i;
  wire       strobe_i;

  wire [7:0] data_o;
  wire       ready;
  wire       done;
  wire       tag_ok;
  wire       busy;

  assign data_i   = ui_in;
  assign cmd_i    = uio_in[7:4];
  assign strobe_i = ena & (cmd_i != 4'h0);

  tt_ascon_core u_core (
    .clk      (clk),
    .rst_n    (rst_n),
    .strobe_i (strobe_i),
    .cmd_i    (cmd_i),
    .data_i   (data_i),
    .data_o   (data_o),
    .ready_o  (ready),
    .done_o   (done),
    .tag_ok_o (tag_ok),
    .busy_o   (busy)
  );

  assign uo_out  = data_o;

  // uio[3:0] are outputs, uio[7:4] are command inputs.
  assign uio_out = {4'b0000, busy, tag_ok, done, ready};
  assign uio_oe  = 8'h0f;

endmodule

`default_nettype wire
