// SPDX-License-Identifier: Apache-2.0
// Minimum-area ASCON permutation.
// Microarchitecture:
// - one 320-bit state register
// - one physical 5-bit S-box
// - 64 S-box columns processed serially per round
// - one combinational 64-bit linear layer step per round
// - supports p12 and p8 through rounds_i = 12 or 8

`default_nettype none

module tt_ascon_perm (
  input  wire         clk,
  input  wire         rst_n,
  input  wire         start_i,
  input  wire [3:0]   rounds_i,
  input  wire [319:0] state_i,
  output wire [319:0] state_o,
  output wire         busy_o,
  output reg          done_o
);

  localparam [2:0]
    P_IDLE   = 3'd0,
    P_CONST  = 3'd1,
    P_SBOX   = 3'd2,
    P_LINEAR = 3'd3;

  reg [2:0]   phase_q;
  reg [319:0] state_q;
  reg [5:0]   col_q;
  reg [3:0]   round_q;
  reg [3:0]   rounds_q;
  reg [3:0]   first_round_q;

  wire [4:0] sbox_i;
  wire [4:0] sbox_o;

  assign sbox_i = {
    state_q[256 + col_q],
    state_q[192 + col_q],
    state_q[128 + col_q],
    state_q[ 64 + col_q],
    state_q[  0 + col_q]
  };

  tt_ascon_sbox5 u_sbox (
    .x_i(sbox_i),
    .x_o(sbox_o)
  );

  assign state_o = state_q;
  assign busy_o  = (phase_q != P_IDLE);

  function [63:0] rotr64;
    input [63:0] x;
    input integer n;
    begin
      rotr64 = (x >> n) | (x << (64 - n));
    end
  endfunction

  function [7:0] round_const;
    input [3:0] r;
    begin
      case (r)
        4'd0:  round_const = 8'hf0;
        4'd1:  round_const = 8'he1;
        4'd2:  round_const = 8'hd2;
        4'd3:  round_const = 8'hc3;
        4'd4:  round_const = 8'hb4;
        4'd5:  round_const = 8'ha5;
        4'd6:  round_const = 8'h96;
        4'd7:  round_const = 8'h87;
        4'd8:  round_const = 8'h78;
        4'd9:  round_const = 8'h69;
        4'd10: round_const = 8'h5a;
        4'd11: round_const = 8'h4b;
        default: round_const = 8'h00;
      endcase
    end
  endfunction

  wire [63:0] x0 = state_q[ 63:  0];
  wire [63:0] x1 = state_q[127: 64];
  wire [63:0] x2 = state_q[191:128];
  wire [63:0] x3 = state_q[255:192];
  wire [63:0] x4 = state_q[319:256];

  wire [63:0] l0 = x0 ^ rotr64(x0, 19) ^ rotr64(x0, 28);
  wire [63:0] l1 = x1 ^ rotr64(x1, 61) ^ rotr64(x1, 39);
  wire [63:0] l2 = x2 ^ rotr64(x2,  1) ^ rotr64(x2,  6);
  wire [63:0] l3 = x3 ^ rotr64(x3, 10) ^ rotr64(x3, 17);
  wire [63:0] l4 = x4 ^ rotr64(x4,  7) ^ rotr64(x4, 41);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      phase_q       <= P_IDLE;
      state_q       <= 320'd0;
      col_q         <= 6'd0;
      round_q       <= 4'd0;
      rounds_q      <= 4'd0;
      first_round_q <= 4'd0;
      done_o        <= 1'b0;
    end else begin
      done_o <= 1'b0;

      case (phase_q)
        P_IDLE: begin
          if (start_i) begin
            state_q  <= state_i;
            col_q    <= 6'd0;
            round_q  <= 4'd0;
            rounds_q <= rounds_i;

            // p12 starts at constant index 0.
            // p8 starts at constant index 4.
            // Other values use the last `rounds_i` constants.
            first_round_q <= 4'd12 - rounds_i;
            phase_q <= P_CONST;
          end
        end

        P_CONST: begin
          // ASCON round constant addition: x2 ^= RC in low byte.
          state_q[135:128] <= state_q[135:128] ^ round_const(first_round_q + round_q);
          col_q <= 6'd0;
          phase_q <= P_SBOX;
        end

        P_SBOX: begin
          state_q[  0 + col_q] <= sbox_o[0];
          state_q[ 64 + col_q] <= sbox_o[1];
          state_q[128 + col_q] <= sbox_o[2];
          state_q[192 + col_q] <= sbox_o[3];
          state_q[256 + col_q] <= sbox_o[4];

          if (col_q == 6'd63) begin
            phase_q <= P_LINEAR;
          end else begin
            col_q <= col_q + 6'd1;
          end
        end

        P_LINEAR: begin
          state_q[ 63:  0] <= l0;
          state_q[127: 64] <= l1;
          state_q[191:128] <= l2;
          state_q[255:192] <= l3;
          state_q[319:256] <= l4;

          if (round_q == (rounds_q - 1'b1)) begin
            phase_q <= P_IDLE;
            done_o  <= 1'b1;
          end else begin
            round_q <= round_q + 4'd1;
            phase_q <= P_CONST;
          end
        end

        default: begin
          phase_q <= P_IDLE;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
