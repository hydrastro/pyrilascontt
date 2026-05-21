// SPDX-License-Identifier: Apache-2.0
// TinyTapeout minimum-area ASCON-AEAD128 first real core.
//
// Current supported operation:
// - AEAD128 encryption only
// - fixed 16-byte key
// - fixed 16-byte nonce
// - fixed 16-byte plaintext
// - no associated data
// - output 16-byte ciphertext then 16-byte tag
//
// Architecture:
// - single 320-bit state register
// - one 5-bit-column serial permutation backend
// - hardcoded FSM
// - no side-channel masking
// - no fault detection
// - no plaintext buffering
//
// Command protocol:
//   CMD_RESET      = f
//   CMD_LOAD_KEY   = 1, send 16 bytes
//   CMD_LOAD_NONCE = 2, send 16 bytes
//   CMD_PT         = 4, send 16 bytes plaintext
//   CMD_FINAL      = 6, starts AEAD computation
//   CMD_READ       = 7, read 32 output bytes: CT[0..15], TAG[0..15]

`default_nettype none

module tt_ascon_core (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       strobe_i,
  input  wire [3:0] cmd_i,
  input  wire [7:0] data_i,
  output reg  [7:0] data_o,
  output wire       ready_o,
  output reg        done_o,
  output reg        tag_ok_o,
  output wire       busy_o
);

  localparam [3:0]
    CMD_NOP        = 4'h0,
    CMD_LOAD_KEY   = 4'h1,
    CMD_LOAD_NONCE = 4'h2,
    CMD_AD         = 4'h3,
    CMD_PT         = 4'h4,
    CMD_CT         = 4'h5,
    CMD_FINAL      = 4'h6,
    CMD_READ       = 4'h7,
    CMD_RESET      = 4'hf;

  localparam [4:0]
    S_IDLE        = 5'd0,
    S_INIT_START  = 5'd1,
    S_INIT_WAIT   = 5'd2,
    S_INIT_KEY    = 5'd3,
    S_PT_BLOCK    = 5'd4,
    S_P8_START    = 5'd5,
    S_P8_WAIT     = 5'd6,
    S_FINAL_KEY1  = 5'd7,
    S_P12_START   = 5'd8,
    S_P12_WAIT    = 5'd9,
    S_FINAL_KEY2  = 5'd10,
    S_DONE        = 5'd11;

  reg [4:0] state_fsm_q;

  reg [319:0] state_q;
  reg [127:0] key_q;
  reg [127:0] nonce_q;
  reg [127:0] pt_q;
  reg [127:0] ct_q;
  reg [127:0] tag_q;

  reg [4:0] key_idx_q;
  reg [4:0] nonce_idx_q;
  reg [4:0] pt_idx_q;
  reg [5:0] out_idx_q;

  reg perm_start_q;
  reg [3:0] perm_rounds_q;
  wire [319:0] perm_state_o;
  wire perm_busy;
  wire perm_done;

  wire core_busy = (state_fsm_q != S_IDLE) && (state_fsm_q != S_DONE);

  assign ready_o = !core_busy;
  assign busy_o  = core_busy | perm_busy;

  tt_ascon_perm u_perm (
    .clk      (clk),
    .rst_n    (rst_n),
    .start_i  (perm_start_q),
    .rounds_i (perm_rounds_q),
    .state_i  (state_q),
    .state_o  (perm_state_o),
    .busy_o   (perm_busy),
    .done_o   (perm_done)
  );

  function [127:0] store_byte_128;
    input [127:0] old_value;
    input [4:0] index;
    input [7:0] byte_value;
    reg [127:0] tmp;
    begin
      tmp = old_value;
      case (index)
        5'd0:  tmp[127:120] = byte_value;
        5'd1:  tmp[119:112] = byte_value;
        5'd2:  tmp[111:104] = byte_value;
        5'd3:  tmp[103: 96] = byte_value;
        5'd4:  tmp[ 95: 88] = byte_value;
        5'd5:  tmp[ 87: 80] = byte_value;
        5'd6:  tmp[ 79: 72] = byte_value;
        5'd7:  tmp[ 71: 64] = byte_value;
        5'd8:  tmp[ 63: 56] = byte_value;
        5'd9:  tmp[ 55: 48] = byte_value;
        5'd10: tmp[ 47: 40] = byte_value;
        5'd11: tmp[ 39: 32] = byte_value;
        5'd12: tmp[ 31: 24] = byte_value;
        5'd13: tmp[ 23: 16] = byte_value;
        5'd14: tmp[ 15:  8] = byte_value;
        5'd15: tmp[  7:  0] = byte_value;
        default: tmp = old_value;
      endcase
      store_byte_128 = tmp;
    end
  endfunction

  function [7:0] read_byte_128;
    input [127:0] value;
    input [4:0] index;
    begin
      case (index)
        5'd0:  read_byte_128 = value[127:120];
        5'd1:  read_byte_128 = value[119:112];
        5'd2:  read_byte_128 = value[111:104];
        5'd3:  read_byte_128 = value[103: 96];
        5'd4:  read_byte_128 = value[ 95: 88];
        5'd5:  read_byte_128 = value[ 87: 80];
        5'd6:  read_byte_128 = value[ 79: 72];
        5'd7:  read_byte_128 = value[ 71: 64];
        5'd8:  read_byte_128 = value[ 63: 56];
        5'd9:  read_byte_128 = value[ 55: 48];
        5'd10: read_byte_128 = value[ 47: 40];
        5'd11: read_byte_128 = value[ 39: 32];
        5'd12: read_byte_128 = value[ 31: 24];
        5'd13: read_byte_128 = value[ 23: 16];
        5'd14: read_byte_128 = value[ 15:  8];
        5'd15: read_byte_128 = value[  7:  0];
        default: read_byte_128 = 8'h00;
      endcase
    end
  endfunction

  // Pack state as x0 in [63:0], x1 in [127:64], etc.
  // IV for ASCON-AEAD128 from NIST SP 800-232/final ASCON family:
  // 0x00001000808c0001 in x0 for AEAD128 initialization.
  function [319:0] initial_state;
    input [127:0] key;
    input [127:0] nonce;
    begin
      initial_state = {
        nonce[63:0],
        nonce[127:64],
        key[63:0],
        key[127:64],
        64'h00001000808c0001
      };
    end
  endfunction

  wire [127:0] s_rate = state_q[127:0];
  wire [127:0] ct_next = s_rate ^ pt_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_fsm_q  <= S_IDLE;
      state_q      <= 320'd0;
      key_q        <= 128'd0;
      nonce_q      <= 128'd0;
      pt_q         <= 128'd0;
      ct_q         <= 128'd0;
      tag_q        <= 128'd0;
      key_idx_q    <= 5'd0;
      nonce_idx_q  <= 5'd0;
      pt_idx_q     <= 5'd0;
      out_idx_q    <= 6'd0;
      perm_start_q <= 1'b0;
      perm_rounds_q <= 4'd0;
      data_o       <= 8'd0;
      done_o       <= 1'b0;
      tag_ok_o     <= 1'b0;
    end else begin
      done_o       <= 1'b0;
      perm_start_q <= 1'b0;

      case (state_fsm_q)
        S_IDLE: begin
          if (strobe_i) begin
            case (cmd_i)
              CMD_RESET: begin
                state_q     <= 320'd0;
                key_q       <= 128'd0;
                nonce_q     <= 128'd0;
                pt_q        <= 128'd0;
                ct_q        <= 128'd0;
                tag_q       <= 128'd0;
                key_idx_q   <= 5'd0;
                nonce_idx_q <= 5'd0;
                pt_idx_q    <= 5'd0;
                out_idx_q   <= 6'd0;
                data_o      <= 8'd0;
                tag_ok_o    <= 1'b0;
                done_o      <= 1'b1;
              end

              CMD_LOAD_KEY: begin
                key_q <= store_byte_128(key_q, key_idx_q, data_i);
                if (key_idx_q != 5'd15) key_idx_q <= key_idx_q + 5'd1;
                done_o <= 1'b1;
              end

              CMD_LOAD_NONCE: begin
                nonce_q <= store_byte_128(nonce_q, nonce_idx_q, data_i);
                if (nonce_idx_q != 5'd15) nonce_idx_q <= nonce_idx_q + 5'd1;
                done_o <= 1'b1;
              end

              CMD_PT: begin
                pt_q <= store_byte_128(pt_q, pt_idx_q, data_i);
                if (pt_idx_q != 5'd15) pt_idx_q <= pt_idx_q + 5'd1;
                done_o <= 1'b1;
              end

              CMD_FINAL: begin
                state_q <= initial_state(key_q, nonce_q);
                state_fsm_q <= S_INIT_START;
              end

              CMD_READ: begin
                if (out_idx_q < 6'd16) begin
                  data_o <= read_byte_128(ct_q, out_idx_q[4:0]);
                end else if (out_idx_q < 6'd32) begin
                  data_o <= read_byte_128(tag_q, out_idx_q[4:0] - 5'd16);
                end else begin
                  data_o <= 8'h00;
                end

                if (out_idx_q != 6'd32) out_idx_q <= out_idx_q + 6'd1;
                done_o <= 1'b1;
              end

              default: begin
                done_o <= 1'b1;
              end
            endcase
          end
        end

        S_INIT_START: begin
          perm_rounds_q <= 4'd12;
          perm_start_q  <= 1'b1;
          state_fsm_q   <= S_INIT_WAIT;
        end

        S_INIT_WAIT: begin
          if (perm_done) begin
            state_q <= perm_state_o;
            state_fsm_q <= S_INIT_KEY;
          end
        end

        S_INIT_KEY: begin

          // Initialization key addition for ASCON-AEAD128:
          // x3 ^= K0, x4 ^= K1.
          state_q[255:192] <= state_q[255:192] ^ key_q[127: 64];
          state_q[319:256] <= state_q[319:256] ^ key_q[ 63:  0];
          state_fsm_q <= S_PT_BLOCK;
        end

        S_PT_BLOCK: begin
          // One full 128-bit plaintext block, no AD.
          ct_q <= ct_next;
          state_q[127:0] <= ct_next;
          state_fsm_q <= S_P8_START;
        end

        S_P8_START: begin
          perm_rounds_q <= 4'd8;
          perm_start_q  <= 1'b1;
          state_fsm_q   <= S_P8_WAIT;
        end

        S_P8_WAIT: begin
          if (perm_done) begin
            state_q <= perm_state_o;
            state_fsm_q <= S_FINAL_KEY1;
          end
        end

        S_FINAL_KEY1: begin

          // Finalization key injection:
          // x1 ^= K0, x2 ^= K1.
          state_q[127: 64] <= state_q[127: 64] ^ key_q[127: 64];
          state_q[191:128] <= state_q[191:128] ^ key_q[ 63:  0];
          state_fsm_q <= S_P12_START;
        end

        S_P12_START: begin
          perm_rounds_q <= 4'd12;
          perm_start_q  <= 1'b1;
          state_fsm_q   <= S_P12_WAIT;
        end

        S_P12_WAIT: begin
          if (perm_done) begin
            state_q <= perm_state_o;
            state_fsm_q <= S_FINAL_KEY2;
          end
        end

        S_FINAL_KEY2: begin

          // Tag output:
          // T0 = x3 ^ K0, T1 = x4 ^ K1.
          tag_q <= {
            state_q[255:192] ^ key_q[127: 64],
            state_q[319:256] ^ key_q[ 63:  0]
          };
          tag_ok_o <= 1'b1;
          out_idx_q <= 6'd0;
          state_fsm_q <= S_DONE;
        end

        S_DONE: begin
          done_o <= 1'b1;
          state_fsm_q <= S_IDLE;
        end

        default: begin
          state_fsm_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
