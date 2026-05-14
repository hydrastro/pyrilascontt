/*
 * Copyright (c) 2026 hydrastro
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_hydrastro_pyrilascon (
    input  wire [7:0] ui_in,    // command/data input
    output wire [7:0] uo_out,   // data/status output
    input  wire [7:0] uio_in,   // auxiliary input pins
    output wire [7:0] uio_out,  // auxiliary output pins
    output wire [7:0] uio_oe,   // 1=output, 0=input
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    /*
     * Temporary TT shell.
     *
     * Next step: replace this with a real serial command bridge:
     *   - load key
     *   - load nonce
     *   - load AD
     *   - load plaintext/ciphertext
     *   - start encrypt/decrypt
     *   - read ciphertext/plaintext/tag/status
     *
     * TinyTapeout exposes only a small pin interface, so full AEAD128 must be
     * accessed through a byte-serial or nibble-serial protocol.
     */

    assign uo_out  = 8'hA5;   // bring-up signature
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;   // all bidirectional pins input for now

    wire _unused = &{ena, clk, rst_n, ui_in, uio_in, 1'b0};

endmodule

`default_nettype wire
