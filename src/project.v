/*
 * Copyright (c) 2026 hydrastro
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

ascon_asic_shared_datapath_aead128_16_bit_one_round_per_cycle_single_core_single_320_register_hardcoded_fsm_rtl_performed_asic_rand_counter_consttime_tag_top #(
    .DATA_BUS_BITS(16)
) u_ascon_core (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(core_start),
    .data_i(core_data_i),
    .data_o(core_data_o),
    .ready_o(core_ready),
    .done_o(core_done)
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
