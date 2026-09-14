%% ========================================================================
%  GUIDE 05 : ROM CONTENT GENERATOR (Q1.4 FIXED-POINT FORMAT)
%  =========================================================================
%
%  PURPOSE OF THIS SCRIPT
%  ------------------------
%  This script converts every lookup table used by the CSS transmitter
%  into the exact bit patterns that belong in RTL ROMs, and writes each
%  one to a plain text file, one line per ROM address, ready to be read
%  by $readmemb or hand-copied into a Verilog `initial` block.
%
%  Five ROMs are generated:
%     STEP 1: Symbol Mapper ROM, 1 Mb/s  (Walsh-Hadamard, 4-chip codewords)
%     STEP 2: Symbol Mapper ROM, 250 kb/s (Walsh-Hadamard, 32-chip codewords)
%     STEP 3: Interleaver permutation ROM (250 kb/s only)
%     STEP 4: QPSK Mapper truth table (4 entries -- not a real ROM, but
%              shown in the same lookup-table format for completeness)
%     STEP 5: CSK Generator / chirp waveform ROM (real + imaginary parts)
%
%  FORMAT USED FOR EACH ROM
%  --------------------------
%  Steps 1-4 store either single BITS (bipolar chips, symbol addresses,
%  permutation indices) or small integers -- none of these are fractional
%  amplitude values, so none of them need a fixed-point format at all.
%
%  Step 5 is different: the chirp waveform is a genuine amplitude value
%  (a sampled sinusoid, windowed by a raised cosine), so it needs a real
%  fixed-point representation. This script uses:
%
%       Q1.4  =  numerictype(1, 6, 4)
%             =  1 sign bit + 1 integer bit + 4 fraction bits = 6 bits total
%             =  range [-2.0000, +1.9375], resolution (1 LSB) = 2^-4 = 0.0625
%
%  WHY Q1.4 IS THE RIGHT FORMAT FOR THIS ROM
%  --------------------------------------------
%  Every stored chirp sample is built from exp(j*theta) (magnitude exactly
%  1) multiplied by a raised-cosine window whose value is always in [0,1].
%  So every real and imaginary component stored in this ROM has magnitude
%  <= 1.0 -- verified directly below against this exact ROM's own computed
%  values. Only 1 integer bit is therefore needed to comfortably represent
%  every stored sample with margin, leaving 4 bits free for fractional
%  precision instead of being wasted on unused integer range. This is the
%  same word length (6 bits) as every other rail in this design, just with
%  the bit budget spent where it is actually useful for THIS ROM's data.
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);
addpath('common');
addpath('transmitter');

outDir = 'rom_output_files';
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

fprintf('\n=========================================================\n');
fprintf(' GUIDE 05 : ROM CONTENT GENERATOR (Q1.4 FORMAT)\n');
fprintf(' All output files will be written to: %s/\n', outDir);
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0a : Populate all the golden-model tables (Symbol Mapper,
%            Interleaver, chirp generator all depend on this)
%  ------------------------------------------------------------------
global codeword_1Mbs codeword_250kbs samplingFreqMhz chirpIndex
chirpIndex = 1;
globalSettings();

%% ------------------------------------------------------------------
%  STEP 0b : LOCK IN THE Q1.4 FORMAT FOR THE CHIRP ROM (STEP 5 ONLY)
%  ------------------------------------------------------------------
IB_chirp = 1;   % integer bits
signBit  = 1;   % sign bit
FL_chirp = 4;   % fraction bits
WL_chirp = signBit + IB_chirp + FL_chirp;   % = 6 bits total

T_sig_chirp  = numerictype(1, WL_chirp, FL_chirp);
F_math_chirp = fimath('RoundingMethod','Nearest','OverflowAction','Saturate', ...
                 'ProductMode','SpecifyPrecision','ProductWordLength',2*WL_chirp-1, ...
                 'ProductFractionLength',2*FL_chirp,'SumMode','SpecifyPrecision', ...
                 'SumWordLength',2*WL_chirp,'SumFractionLength',FL_chirp);

fprintf('--- STEP 0b: Fixed-point format locked in for the chirp ROM ---\n');
fprintf('  numerictype(1,%d,%d)  =  Q%d.%d\n', WL_chirp, FL_chirp, IB_chirp, FL_chirp);
fprintf('  Word length             : %d bits (1 sign + %d integer + %d fraction)\n', WL_chirp, IB_chirp, FL_chirp);
fprintf('  Resolution (1 LSB step) : 2^-%d = %.6f\n', FL_chirp, 2^-FL_chirp);
fprintf('  Representable range     : [%.4f, %.4f]\n\n', -2^IB_chirp, 2^IB_chirp - 2^-FL_chirp);

%% ========================================================================
%  STEP 1 : SYMBOL MAPPER ROM (1 Mb/s, Walsh-Hadamard, 4-chip codewords)
%  ========================================================================
%  This table converts a 3-bit data symbol (address 0-7) into its 4-chip
%  bi-orthogonal codeword. Each chip is a single bipolar value (+1 or -1)
%  -- no fixed-point format applies here, only 1 bit per chip is needed.
% ------------------------------------------------------------------------
fprintf('--- STEP 1: Symbol Mapper ROM (1 Mb/s, Walsh-Hadamard 4-chip) ---\n');
fprintf('  Table size : %d rows (addresses 0-%d) x %d chips/row, 1 bit/chip\n', ...
    size(codeword_1Mbs,1), size(codeword_1Mbs,1)-1, size(codeword_1Mbs,2));

codeword_1Mbs_bits = (codeword_1Mbs + 1) / 2;   % bipolar +-1 -> 1/0

fname1 = fullfile(outDir, 'ROM_SymbolMapper_1Mbps_WalshHadamard_4chip_1bitPerChip.txt');
fid = fopen(fname1, 'wt');
fprintf(fid, '// ROM: Symbol Mapper, 1 Mb/s data rate, Walsh-Hadamard bi-orthogonal 4-chip codewords\n');
fprintf(fid, '// Format: 1 BIT per chip (bit=1 -> bipolar +1, bit=0 -> bipolar -1)\n');
fprintf(fid, '// Address = 3-bit decimal symbol value (0 to 7)\n');
fprintf(fid, '// Each line = one address'' 4 chip-bits, MSB-first, NO spaces\n');
for row = 1:size(codeword_1Mbs_bits,1)
    fprintf(fid, '%s\n', sprintf('%d', codeword_1Mbs_bits(row,:)));
end
fclose(fid);
fprintf('  Written : %s\n\n', fname1);

%% ========================================================================
%  STEP 2 : SYMBOL MAPPER ROM (250 kb/s, Walsh-Hadamard, 32-chip codewords)
%  ========================================================================
fprintf('--- STEP 2: Symbol Mapper ROM (250 kb/s, Walsh-Hadamard 32-chip) ---\n');
fprintf('  Table size : %d rows (addresses 0-%d) x %d chips/row, 1 bit/chip\n', ...
    size(codeword_250kbs,1), size(codeword_250kbs,1)-1, size(codeword_250kbs,2));

codeword_250kbs_bits = (codeword_250kbs + 1) / 2;

fname2 = fullfile(outDir, 'ROM_SymbolMapper_250kbps_WalshHadamard_32chip_1bitPerChip.txt');
fid = fopen(fname2, 'wt');
fprintf(fid, '// ROM: Symbol Mapper, 250 kb/s data rate, Walsh-Hadamard bi-orthogonal 32-chip codewords\n');
fprintf(fid, '// Format: 1 BIT per chip (bit=1 -> bipolar +1, bit=0 -> bipolar -1)\n');
fprintf(fid, '// Address = 6-bit decimal symbol value (0 to 63)\n');
fprintf(fid, '// Each line = one address'' 32 chip-bits, MSB-first, NO spaces\n');
for row = 1:size(codeword_250kbs_bits,1)
    fprintf(fid, '%s\n', sprintf('%d', codeword_250kbs_bits(row,:)));
end
fclose(fid);
fprintf('  Written : %s\n\n', fname2);

%% ========================================================================
%  STEP 3 : INTERLEAVER PERMUTATION ROM (250 kb/s only)
%  ========================================================================
%  This ROM does not hold amplitude data at all -- it holds input ADDRESS
%  indices, defining which input chip position feeds each output position.
% ------------------------------------------------------------------------
fprintf('--- STEP 3: Interleaver permutation ROM (250 kb/s only) ---\n');

output_indices = [0  1  2  3  52 53 54 55 8  9  10 11 60 61 62 63 ...
                  16 17 18 19 36 37 38 39 24 25 26 27 44 45 46 47 ...
                  32 33 34 35 20 21 22 23 40 41 42 43 28 29 30 31 ...
                  48 49 50 51 4  5  6  7  56 57 58 59 12 13 14 15];

fprintf('  Table size : %d entries (addresses 0-63), each a 6-bit index (0-63)\n', length(output_indices));

fname3 = fullfile(outDir, 'ROM_Interleaver_250kbps_PermutationIndex_6bit.txt');
fid = fopen(fname3, 'wt');
fprintf(fid, '// ROM: Bit Interleaver permutation table, 250 kb/s data rate ONLY\n');
fprintf(fid, '// Address = output chip position (0 to 63)\n');
fprintf(fid, '// Data = input chip position to fetch for that output (0 to 63), 6-bit unsigned binary\n');
fprintf(fid, '// i.e. output_chip[addr] = input_chip_buffer[ ROM(addr) ]\n');
for i = 1:length(output_indices)
    fprintf(fid, '%s\n', dec2bin(output_indices(i), 6));
end
fclose(fid);
fprintf('  Written : %s\n\n', fname3);

%% ========================================================================
%  STEP 4 : QPSK MAPPER TRUTH TABLE (4-entry lookup)
%  ========================================================================
%  Every QPSK Mapper output component is exactly +1, 0, or -1 -- this is
%  a pure case-statement lookup, never a real multiplier in hardware.
% ------------------------------------------------------------------------
fprintf('--- STEP 4: QPSK Mapper 4-entry truth table ---\n');

I_vals = [ 1  1 -1 -1];
Q_vals = [ 1 -1  1 -1];
X_complex = ((I_vals + Q_vals) - 1i*(I_vals - Q_vals)) / 2;

fname4 = fullfile(outDir, 'ROM_QPSKMapper_4entry_TruthTable.txt');
fid = fopen(fname4, 'wt');
fprintf(fid, '// Truth table: QPSK Mapper, 4-entry lookup (NOT a real multiplier)\n');
fprintf(fid, '// Address = {I,Q} bipolar chip values. Output = X = XI + j*XQ\n');
fprintf(fid, '// Every output component is exactly +1, 0, or -1\n');
fprintf(fid, '// Format: I Q | XI XQ\n');
for k = 1:4
    fprintf(fid, '{I=%2d,Q=%2d} | X = %2d + j*(%2d)\n', I_vals(k), Q_vals(k), ...
        round(real(X_complex(k))), round(imag(X_complex(k))));
end
fclose(fid);
fprintf('  Table size : 4 entries\n');
fprintf('  Written : %s\n\n', fname4);

%% ========================================================================
%  STEP 5 : CSK GENERATOR / CHIRP WAVEFORM ROM (Q1.4, real + imaginary)
%  ========================================================================
fprintf('--- STEP 5: CSK Generator / chirp waveform ROM (Q1.4) ---\n');

chirpIndex = 1;
globalSettings();

chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
close(gcf);

fprintf('  Chirp sequence size : %d samples/subchirp x %d subchirps (chirpIndex=%d)\n', ...
    size(chirpSequence_float,1), size(chirpSequence_float,2), chirpIndex);

% Confirm every stored value actually fits the Q1.4 range before writing
% the ROM -- if this check ever fails, the assumption that the chirp
% waveform is magnitude-bounded by 1 needs to be re-examined.
maxAbsReal = max(abs(real(chirpSequence_float(:))));
maxAbsImag = max(abs(imag(chirpSequence_float(:))));
q14MaxRange = 2^IB_chirp - 2^-FL_chirp;
fprintf('  Max |real| = %.6f, Max |imag| = %.6f  (Q1.4 max representable = %.4f)\n', ...
    maxAbsReal, maxAbsImag, q14MaxRange);
if maxAbsReal > q14MaxRange || maxAbsImag > q14MaxRange
    warning('Chirp sequence exceeds Q1.4 range -- saturation will occur. Re-check assumptions.');
else
    fprintf('  OK: all values fit within Q1.4 range with margin, no saturation expected.\n');
end

chirpSequence_fixed = fi(chirpSequence_float, T_sig_chirp, F_math_chirp);

TsubVal = size(chirpSequence_float,1);
numSubchirps = size(chirpSequence_float,2);

% ---- Real part ROM ----
fname5r = fullfile(outDir, sprintf('ROM_CSKModulator_ChirpIndex%d_REALpart_Q1p4.txt', chirpIndex));
fid = fopen(fname5r, 'wt');
fprintf(fid, '// ROM: CSK Generator / Modulation stage, REAL part of chirp waveform\n');
fprintf(fid, '// Chirp sequence index (m) = %d -- raised-cosine window ALREADY applied\n', chirpIndex);
fprintf(fid, '// Format: Q1.4 signed fixed point, WL=6 bits (1 sign + 1 integer + 4 fraction)\n');
fprintf(fid, '// %d samples per subchirp x %d subchirps = %d total entries\n', TsubVal, numSubchirps, TsubVal*numSubchirps);
fprintf(fid, '// Address order: subchirp 1 samples 1..%d, then subchirp 2, then 3, then 4\n', TsubVal);
fprintf(fid, '// (i.e. address = subchirp_index*%d + sample_index, both 0-based)\n', TsubVal);
for k = 1:numSubchirps
    for n = 1:TsubVal
        fprintf(fid, '%s\n', bin(real(chirpSequence_fixed(n,k))));
    end
end
fclose(fid);
fprintf('  Written (REAL) : %s\n', fname5r);

% ---- Imaginary part ROM ----
fname5i = fullfile(outDir, sprintf('ROM_CSKModulator_ChirpIndex%d_IMAGpart_Q1p4.txt', chirpIndex));
fid = fopen(fname5i, 'wt');
fprintf(fid, '// ROM: CSK Generator / Modulation stage, IMAGINARY part of chirp waveform\n');
fprintf(fid, '// Chirp sequence index (m) = %d -- raised-cosine window ALREADY applied\n', chirpIndex);
fprintf(fid, '// Format: Q1.4 signed fixed point, WL=6 bits (1 sign + 1 integer + 4 fraction)\n');
fprintf(fid, '// %d samples per subchirp x %d subchirps = %d total entries\n', TsubVal, numSubchirps, TsubVal*numSubchirps);
fprintf(fid, '// Address order: subchirp 1 samples 1..%d, then subchirp 2, then 3, then 4\n', TsubVal);
fprintf(fid, '// (i.e. address = subchirp_index*%d + sample_index, both 0-based)\n', TsubVal);
for k = 1:numSubchirps
    for n = 1:TsubVal
        fprintf(fid, '%s\n', bin(imag(chirpSequence_fixed(n,k))));
    end
end
fclose(fid);
fprintf('  Written (IMAG) : %s\n\n', fname5i);

%% ------------------------------------------------------------------
%  SANITY CHECK: quantization MSE for the chirp ROM against the spec's
%  0.005 requirement (Sec 6.5a.5.1).
% ---------------------------------------------------------------------
errChirp = abs(chirpSequence_float - double(chirpSequence_fixed)).^2;
mseChirp = mean(errChirp(:));

fprintf('--- Sanity check: chirp ROM quantization MSE (Q1.4) ---\n');
fprintf('  Measured MSE           : %.8f\n', mseChirp);
if mseChirp <= 0.005
    mseChirpStr = 'PASSED';
else
    mseChirpStr = 'FAILED';
end
fprintf('  Requirement (<=0.005)  : %s\n\n', mseChirpStr);

%% ------------------------------------------------------------------
%  FINAL SUMMARY
%  ------------------------------------------------------------------
fprintf('=========================================================\n');
fprintf(' ROM GENERATION COMPLETE. Files written to: %s/\n', outDir);
fprintf('   1. %s\n', fname1);
fprintf('   2. %s\n', fname2);
fprintf('   3. %s\n', fname3);
fprintf('   4. %s\n', fname4);
fprintf('   5. %s\n', fname5r);
fprintf('   6. %s\n', fname5i);
fprintf('=========================================================\n');