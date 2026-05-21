# PyrilAscon TinyTapeout min-area core

Target architecture:

- ASCON-AEAD128 only
- single 320-bit state register
- 128-bit key register
- 5-bit column-serial permutation
- hardcoded FSM
- byte-oriented Tiny Tapeout protocol
- no masking
- no fault detection
- no random counter hardening
- no plaintext buffering

Current status:

The repository has been prepared for the real min-area implementation. The
module boundaries are now correct, but the permutation and AEAD FSM still need
to be implemented before hardening.

Do not submit this version to Tiny Tapeout as a cryptographic implementation.
