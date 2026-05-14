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

    wire        core_start;
    wire [15:0] core_data_i;
    wire [15:0] core_data_o;
    wire        core_ready;
    wire        core_done;

    // Temporary compact TT bridge.
    // ui_in[7] is start; ui_in[6:0] plus uio_in form a 16-bit payload.
    assign core_start = ena & ui_in[7];
    assign core_data_i = {uio_in, ui_in};

    tt_ascon_core #(
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

    assign uo_out  = core_data_o[7:0];
    assign uio_out = {6'b0, core_done, core_ready};
    assign uio_oe  = 8'h03; // uio[0]=ready, uio[1]=done are outputs

    wire _unused = &{core_data_o[15:8], 1'b0};

endmodule

`default_nettype wire
