## How it works

PyrilAscon is a TinyTapeout-oriented hardware experiment for **Ascon-AEAD128**, the authenticated encryption mode standardized by NIST SP 800-232.

The design wraps a compact ASCON core behind the standard TinyTapeout user-module interface:

- `ui_in[7:0]` is used as an input command/data byte bus.
- `uo_out[7:0]` is used as an output data/status byte bus.
- `uio[0]` is used as a ready/status signal.
- `uio[1]` is used as a done/status signal.
- The remaining `uio` pins are reserved for future status, debug, or flow-control signals.

Internally, the selected TinyTapeout architecture is intended to be a compact ASIC-style AEAD128 implementation:

- single shared ASCON core
- one operation at a time
- 16-bit internal datapath
- one permutation round per cycle
- single 320-bit ASCON state register
- hardcoded control FSM
- RTL-performed padding
- constant-time tag comparison
- randomized counter hardening hooks

The ASCON state is five 64-bit words, for a total of 320 bits. The AEAD128 operation uses a 128-bit key, 128-bit nonce, associated data, plaintext or ciphertext, and a 128-bit authentication tag.

For decryption, the intended security policy is to buffer plaintext internally until the authentication tag has been verified. If the tag check fails, plaintext must not be released.

At the current integration stage, this TinyTapeout wrapper is structured to connect the TinyTapeout pins to the compact PyrilAscon AEAD128 core. The full AEAD command protocol and final tapeout-ready RTL should be verified with known-answer tests before submission.

## How to test

The basic bring-up test checks that the TinyTapeout wrapper can be reset, clocked, and driven through its input pins.

A typical test sequence is:

1. Hold `rst_n` low to reset the design.
2. Release reset by setting `rst_n` high.
3. Drive command/data bytes on `ui_in[7:0]`.
4. Pulse or assert the command/start bit according to the testbench protocol.
5. Observe `uo_out[7:0]` and the status pins on `uio_out`.

For full ASCON testing, the design should be tested against known-answer tests for Ascon-AEAD128:

- load a 128-bit key
- load a 128-bit nonce
- load associated data
- load plaintext for encryption, or ciphertext and tag for decryption
- start the operation
- read ciphertext/plaintext and tag/status bytes
- compare against the expected known-answer test vector

The software-side PyrilAscon model includes Python tests and known-answer vectors. Those tests should be used as the reference when validating the hardware wrapper and the final RTL implementation.

## External hardware

No external hardware is required.

The design uses only the standard TinyTapeout digital input, output, bidirectional, clock, enable, and reset pins.
