# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


KEY = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
NONCE = bytes.fromhex("101112131415161718191a1b1c1d1e1f")
PT = bytes.fromhex("202122232425262728292a2b2c2d2e2f")
EXP_CT = bytes.fromhex("52fd20d46d5c40056bf294aff2892cf1")
EXP_TAG = bytes.fromhex("3442b7197ba19564a24b9354c007e5bb")


def _uio_out(dut) -> int:
    return int(dut.uio_out.value)


def _ready(dut) -> bool:
    return bool(_uio_out(dut) & 0x01)


def _done(dut) -> bool:
    return bool(_uio_out(dut) & 0x02)


def _tag_ok(dut) -> bool:
    return bool(_uio_out(dut) & 0x04)


async def wait_ready(dut, limit=10000):
    for _ in range(limit):
        if _ready(dut):
            return
        await RisingEdge(dut.clk)
    raise AssertionError("timeout waiting for ready")


async def wait_done(dut, limit=100000):
    for _ in range(limit):
        if _done(dut):
            await RisingEdge(dut.clk)
            return
        await RisingEdge(dut.clk)
    raise AssertionError("timeout waiting for done")


async def send_cmd_byte(dut, cmd: int, data: int = 0):
    await wait_ready(dut)
    dut.ui_in.value = data & 0xFF
    dut.uio_in.value = (cmd & 0xF) << 4
    await RisingEdge(dut.clk)

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await wait_done(dut)


async def reset_dut(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)


@cocotb.test()
async def encrypt16_wrapper_kat(dut):
    """TinyTapeout wrapper KAT: ASCON-AEAD128 encrypt, 16-byte PT, no AD."""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    assert int(dut.uio_oe.value) == 0x0F, f"uio_oe={int(dut.uio_oe.value):02x}"

    # CMD_RESET
    await send_cmd_byte(dut, 0xF, 0x00)

    for b in KEY:
        await send_cmd_byte(dut, 0x1, b)

    for b in NONCE:
        await send_cmd_byte(dut, 0x2, b)

    for b in PT:
        await send_cmd_byte(dut, 0x4, b)

    # CMD_FINAL computes CT+TAG.
    await send_cmd_byte(dut, 0x6, 0x00)

    assert _tag_ok(dut), "tag_ok not asserted after encrypt final"

    expected = EXP_CT + EXP_TAG

    for i, exp in enumerate(expected):
        await send_cmd_byte(dut, 0x7, 0x00)
        got = int(dut.uo_out.value)
        assert got == exp, f"output byte {i}: got=0x{got:02x} exp=0x{exp:02x}"
