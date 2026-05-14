# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start PyrilAscon TT scaffold test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 4)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    assert int(dut.uio_out.value) & 0x01 == 1  # ready

    dut.ui_in.value = 0xA5  # start bit set, payload low byte = 0xA5
    dut.uio_in.value = 0x3C
    await ClockCycles(dut.clk, 1)

    assert int(dut.uo_out.value) == 0xA5
    assert (int(dut.uio_out.value) & 0x03) == 0x03  # ready + done
