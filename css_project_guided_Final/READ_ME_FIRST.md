# CSS Transmitter — Orientation Guide

Read this before running anything. It answers the questions you asked directly.

## 1. "Is `runMe.m` the top module or the testbench?"

**It's the testbench.** Your actual design (the DUT) is the set of functions:

| Block in your diagram | MATLAB file |
|---|---|
| Zero Padding, Demux, S/P, Symbol Mapper, Interleaver, Form PPDU, QPSK Mapper, DQPSK coding | `ChirpSpreadSpectrum_Tx.m` (this ONE function contains ALL of these sub-blocks — read it top to bottom, each section is labeled with its spec clause, e.g. `6.5a.2.2 De-multiplexer`) |
| CSK Generator | `chirpSequenceGenerator.m` |
| Raised cosine pulse shaping (used inside CSK generator) | `raisedCosineGen.m` |
| Interleaver (only used for 250 kb/s) | `bitInterleaver.m` (called *from inside* `ChirpSpreadSpectrum_Tx.m`) |
| Final chirp modulation (the two `⊗` multipliers + CSK generator feed) | `chirpModulation.m` (called from inside `ChirpSpreadSpectrum_Tx.m`) |
| Parameters / ROM tables (preamble, SFD, Hadamard codewords, timing) | `globalSettings.m` |

`runMe.m` and `simulationParameters.m` only pick test conditions (which data rate, chirp index, payload length, SNR sweep) and call the design. **You should rarely need to edit the algorithm files. You edit `simulationParameters.m` to change test conditions.**

## 2. "I don't understand QPSK / DQPSK / CSK / CSS"

Rough plain-English version, matched to your diagram left-to-right:

- **Zero Padding**: your payload bits + a 12-bit header (PHR) get padded with zero bits so the total length divides evenly into symbol-sized chunks (6 bits for 1 Mb/s, 24 bits for 250 kb/s).
- **Demux**: bits alternate — bit 1 goes to the "I" path, bit 2 to the "Q" path, bit 3 to I, bit 4 to Q, etc. You now have two parallel bitstreams.
- **Symbol Mapper**: each path's bits are grouped into small chunks (3 bits, or 6 bits) and each chunk is looked up in a table (`codeword_1Mbs`/`codeword_250kbs`, built from a Hadamard matrix) and replaced by a longer "codeword" of +1/-1 chips. This is *redundancy for error protection* — like a repetition/parity code, not compression.
- **Interleaver**: (250 kb/s only) shuffles chip order between pairs of codewords so that a burst error in the channel gets spread out instead of wiping out one whole symbol.
- **Form PPDU**: the Preamble and SFD (fixed, known bit patterns used for the receiver to detect "a packet has started") get glued onto the front of the I and Q chip streams.
- **QPSK Mapper**: this is just "take one I-bit and one Q-bit, make one complex number out of them." QPSK = 4 possible complex values (4 points on a circle, 90° apart) — that's it. `X_n = ((I+Q) - j(I-Q))/2` is just the formula that picks the right one of those 4 points for each I/Q bit pair.
- **DQPSK coding**: **Differential** QPSK. Instead of sending the absolute point on the circle, you send *the phase difference from 4 symbols ago* (`S_n = X_n × S_{n-4}`, where `S_{n-4}` comes from a 4-deep feedback register, drawn as `Z⁻⁴` in your diagram). This makes the receiver's job easier (doesn't need a perfect absolute phase reference).
- **CSK Generator**: generates 4 special waveforms called "subchirps" — signals whose frequency sweeps up or down over time in one of 4 specific patterns.
- **CSS = Chirp Spread Spectrum**: the *actual modulation trick*. Instead of sending your DQPSK symbol as a simple pulse, you multiply it onto one of those frequency-sweeping subchirp waveforms. The **frequency sweep IS the modulation** — a receiver correlates against all 4 possible chirp shapes to figure out which subchirp direction/pattern was used, which recovers the symbol, and is very robust to noise and multipath because chirps are easy to detect even when weak.

**Run `GUIDE_01_floatingPointWalkthrough.m`** — it plots literally every one of these stages in order, labeled, with the real numbers so you can watch the transformation happen instead of just reading about it.

## 3. "I don't know what the inputs/outputs should look like"

From `GUIDE_01`:
- **Input**: a flat vector of 0s and 1s (`incomingStream`), e.g. `[1 0 1 1 0 0 1 0 ...]` — random payload bits.
- **CSK Generator output**: a `Tsub × 4` complex matrix (each column = one subchirp waveform, ~38 samples long for 32 MHz sampling).
- **Symbol Mapper output**: an `numCodeWords × codeWordLength` matrix of +1/-1 values (bipolar chips), separately for I and Q.
- **QPSK Mapper output (`X_n`)**: a complex column vector, each value one of exactly 4 points: `1+j, 1-j, -1+j, -1-j` (before any scaling).
- **DQPSK output (`S_n`)**: also complex, unit-magnitude-ish, but now the *phase* carries the accumulated difference information, not just directly a 2-bit mapping.
- **Final CSS output (`TxchirpSequences`)**: a long complex vector — this is literally your transmitted baseband signal, in samples, ready for a DAC.

## 4. "I don't understand floating vs fixed point, or how to pick word length / fraction length"

This is the entire subject of `GUIDE_02_fixedPointConversion.m`. Short version:

- **Floating point** = infinite-ish precision, used as your **golden reference** to prove the algorithm (the block diagram) is mathematically correct. This is what you already have — the existing `.m` files as given ARE the floating-point architecture. **Do not modify their algorithm.**
- **Fixed point** = the same exact algorithm, but every number is rounded to a fixed number of bits (`fi()` objects), exactly modelling what a real ADC, DAC, multiplier, or adder in hardware would do.
- **You are NOT inventing a new architecture for fixed-point.** You take the given floating-point signal flow as-is and insert quantization at each arithmetic operation, using `numerictype(signed, WordLength, FractionLength)` + `fimath(...)`.
- **How to choose WordLength/FractionLength**: sweep FractionLength from small to large, quantize your signal at each value, compute `MSE = mean(abs(floating - fixed).^2)`, and pick the smallest FractionLength that still satisfies `MSE <= 0.005`. `GUIDE_02` does exactly this sweep and plots MSE vs FractionLength so you can see the tradeoff with your own eyes, then locks in WL=12, FL=9 as the chosen format (matching your original script) and re-validates it on the FULL transmitter chain, not just one signal in isolation.

## 5. Recommended order to run things

1. `GUIDE_01_floatingPointWalkthrough.m` — understand the algorithm, stage by stage, floating point only. **No fixed-point concepts introduced yet.** Run this until every plot makes sense to you.
2. `GUIDE_02_fixedPointConversion.m` — now layer fixed-point quantization on top of the exact same signal flow, with the MSE-vs-FractionLength sweep front and center.
3. Only after both make sense, go back to your original `fixedPointTransceiverModel.m` (the full-model script with the loop over data rates) — it will now read as "the same two guide files, but looped and exported to files for the RTL testbench," instead of a wall of unfamiliar code.

## 6. Where do the `.txt` files fit in?

`payload.txt`, `preambleSFD.txt`, `codeword_1Mbs.txt`, `codeword_250kbs.txt`, `chirpSequence*.txt` are **golden vector files** — they're written BY the MATLAB floating/fixed-point model so that a separate VHDL/ModelSim testbench (`transmitter_linkModleSim.m`) can compare RTL simulation output against them, bit for bit. They are outputs of verification, not inputs you need to hand-construct.
