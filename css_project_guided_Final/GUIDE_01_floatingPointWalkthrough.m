%% ========================================================================
%  GUIDE 01 : FLOATING-POINT CSS TRANSMITTER — GUIDED WALKTHROUGH
%  =========================================================================
%
%  WHAT THIS FILE IS
%  ------------------
%  This is a TESTBENCH, exactly like a hardware testbench: it does not
%  contain any DSP algorithm itself. It only:
%     1) sets up stimulus (payload bits, configuration),
%     2) calls your DESIGN functions (globalSettings, ChirpSpreadSpectrum_Tx,
%        chirpSequenceGenerator, chirpModulation ...),
%     3) probes the INTERNAL SIGNALS of those functions (the same way you'd
%        add "add wave" probes on internal RTL signals in ModelSim), and
%     4) plots every stage so you can SEE the data transform step by step.
%
%  Your actual "chip" (the design under test) is spread across these files:
%     common/globalSettings.m          -> generates constants + tables (like
%                                          a parameters/ROM package in RTL)
%     common/chirpSequenceGenerator.m  -> the CSK generator block
%     common/raisedCosineGen.m         -> pulse shaping window generator
%     common/bitInterleaver.m          -> the Interleaver block
%     common/binary2decimal.m /
%     common/decimal2binary.m         -> bit <-> symbol index utilities
%     transmitter/ChirpSpreadSpectrum_Tx.m -> the TOP-LEVEL transmitter,
%                                          i.e. it wires together Zero
%                                          Padding -> Demux -> Symbol Mapper
%                                          -> Interleaver -> Form PPDU ->
%                                          QPSK Mapper -> DQPSK coding, then
%                                          calls chirpModulation to produce
%                                          the CSS signal.
%     transmitter/chirpModulation.m   -> DQCSK modulation block (the last
%                                          two multipliers in your diagram)
%
%  RULE OF THUMB FOR "WHERE DO I EDIT?"
%  -------------------------------------
%  - Change a TEST CONDITION (payload length, chirp index, data rate)
%      -> edit simulationParameters.m / this guide script's CONFIG section.
%  - Change ALGORITHM BEHAVIOUR (how a block computes its output)
%      -> edit the function file for that block (e.g. chirpModulation.m).
%  - Change PRECISION / WORD LENGTH (fixed-point conversion)
%      -> this is done in a SEPARATE fixed-point wrapper (GUIDE_02), you do
%         NOT hack fixed-point rounding into the floating-point algorithm
%         files. Keep the golden floating-point model completely clean.
%
%  This first guide file runs ONLY the floating-point (golden reference)
%  model, and plots every internal signal along the block diagram, labelled
%  with the exact section number from the spec, so you can match each plot
%  to a box in your architecture picture.
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);

addpath('common');
addpath('transmitter');

fprintf('\n');
fprintf('=========================================================\n');
fprintf(' GUIDE 01 : FLOATING-POINT CSS TRANSMITTER WALKTHROUGH\n');
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0 : CONFIGURATION (this is your "testbench stimulus setup")
%  ------------------------------------------------------------------
%  These are the only "knobs" you should be turning during exploration.
%  Nothing algorithmic lives here.
% ---------------------------------------------------------------------

global chirpIndex samplingFreqMhz carrierFreqGHz codeWordLengthStd ...
       preambleLengthStd Tchirp Tsub TxDACbitNumber ...
       chirpSequenceNumBit_Rx TxChirpSequencesLength SFD_Std SFDlength ...
       PHRlength numBitsPerCodeWordStd codeword_1Mbs codeword_250kbs

chirpIndex   = 1;      % which of the 4 chirp sequences (m = 1,2,3,4)
dataRate     = 0;      % 0 = 1 Mb/s (mandatory rate) , 1 = 250 kb/s (optional)
payloadBytes = 4;      % SMALL payload on purpose: with a big payload the
                        % plots become an unreadable wall of samples. 4
                        % bytes (32 bits) is plenty to see every stage
                        % clearly while you're learning. Increase later.

% This populates ALL the global constants: sampling frequency, carrier
% frequency, preamble/SFD tables, Hadamard codeword tables, chirp timing,
% DAC bit widths, etc. Think of it as "apply reset, load parameter ROM".
globalSettings();

if dataRate==0
    rateStr = '1 Mb/s';
else
    rateStr = '250 kb/s';
end

fprintf('Configuration:\n');
fprintf('  Data rate           : %s\n', rateStr);
fprintf('  Chirp index (m)     : %d\n', chirpIndex);
fprintf('  Sampling frequency  : %d MHz\n', samplingFreqMhz);
fprintf('  Carrier frequency   : %.2f GHz\n', carrierFreqGHz);
fprintf('  Payload length      : %d bytes (%d bits)\n', payloadBytes, payloadBytes*8);
fprintf('  Tchirp (chirp len)  : %d samples\n', Tchirp);
fprintf('  Tsub (subchirp len) : %d samples\n\n', Tsub);

%% ------------------------------------------------------------------
%  STEP 1 : GENERATE STIMULUS — the raw payload bits (PHR+PSDU input)
%  ------------------------------------------------------------------
%  In hardware terms: this is the data you'd load into a testbench stimulus
%  array before starting the clock. Random bits, but seeded (rand('state',0)
%  above) so it is repeatable every time you run this script.
% ---------------------------------------------------------------------

incomingStream = randi([0 1], 1, payloadBytes*8);

figure('Name','STAGE 0 - Raw Input Bitstream','Color','w');
stem(incomingStream, 'filled', 'MarkerSize', 4);
ylim([-0.2 1.2]);
grid on;
title({'STAGE 0: Raw payload bits (incomingStream) — the PSDU going INTO the PHR builder', ...
       'This is the "PHR and PSDU" arrow entering "Zero Padding" in your block diagram'});
xlabel('Bit index'); ylabel('Bit value');

%% ------------------------------------------------------------------
%  STEP 2 : GENERATE THE CHIRP SEQUENCE (the CSK Generator block)
%  ------------------------------------------------------------------
%  This is computed ONCE per chirpIndex and reused for every group of 4
%  DQPSK symbols later. Think of it as a ROM/LUT that your modulator reads
%  from repeatedly — it does not depend on the payload data at all.
% ---------------------------------------------------------------------

chirpSequence = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
% NOTE: chirpSequenceGenerator.m ALSO opens its own figure internally
% (the instantaneous-frequency chirp sweep plot) - that is the classic
% "figure 20c" plot showing frequency vs time for the 4 subchirps.

figure('Name','STAGE 1 - CSK Generator Output (all 4 subchirps)','Color','w');
subplot(2,1,1);
plot(real(chirpSequence(:,1)),'b-','LineWidth',1.3); hold on;
plot(real(chirpSequence(:,2)),'r-','LineWidth',1.3);
plot(real(chirpSequence(:,3)),'g-','LineWidth',1.3);
plot(real(chirpSequence(:,4)),'k-','LineWidth',1.3); hold off;
grid on; legend('subchirp k=1','k=2','k=3','k=4','Location','best');
title('STAGE 1a: CSK Generator - REAL part of the 4 subchirp waveforms');
xlabel('Sample index within subchirp (0..Tsub-1)'); ylabel('Amplitude');

subplot(2,1,2);
plot(imag(chirpSequence(:,1)),'b-','LineWidth',1.3); hold on;
plot(imag(chirpSequence(:,2)),'r-','LineWidth',1.3);
plot(imag(chirpSequence(:,3)),'g-','LineWidth',1.3);
plot(imag(chirpSequence(:,4)),'k-','LineWidth',1.3); hold off;
grid on; legend('subchirp k=1','k=2','k=3','k=4','Location','best');
title({'STAGE 1b: CSK Generator - IMAGINARY part of the 4 subchirp waveforms', ...
       'These 4 columns are the raw subchirps that will be MULTIPLIED by DQPSK symbols later'});
xlabel('Sample index within subchirp (0..Tsub-1)'); ylabel('Amplitude');

%% ------------------------------------------------------------------
%  STEP 3 : RUN THE FULL TRANSMITTER, BUT WITH INSTRUMENTATION
%  ------------------------------------------------------------------
%  ChirpSpreadSpectrum_Tx.m stores several of its INTERNAL signals into
%  GLOBAL variables specifically so a testbench like this one can probe
%  them (look inside that file: I_path_mapped_biOrthogonal,
%  Q_path_mapped_biOrthogonal, and DQPSK_input are declared global).
%  This is the MATLAB equivalent of "add wave sim:/css_tx/internal_signal"
%  in a waveform viewer.
% ---------------------------------------------------------------------

global I_path_mapped_biOrthogonal Q_path_mapped_biOrthogonal DQPSK_input

TxchirpSequences_float = ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence);

fprintf('Transmitter run complete.\n');
fprintf('  Output CSS signal length : %d complex samples\n\n', length(TxchirpSequences_float));

%% ------------------------------------------------------------------
%  STEP 4 : PLOT THE SYMBOL MAPPER + INTERLEAVER OUTPUT (I and Q)
%  ------------------------------------------------------------------
%  I_path_mapped_biOrthogonal / Q_path_mapped_biOrthogonal are the
%  bi-orthogonal CODEWORDS after table lookup (Symbol Mapper block),
%  and — for 250 kb/s only — after the Interleaver permutation.
%  Each ROW is one codeword (4 chips for 1Mb/s, 32 chips for 250kb/s).
% ---------------------------------------------------------------------

figure('Name','STAGE 2 - Symbol Mapper / Interleaver output (I & Q)','Color','w');
subplot(2,1,1);
imagesc(I_path_mapped_biOrthogonal); colormap(gray); colorbar;
title('STAGE 2a: I path — bi-orthogonal codewords (one row per data symbol)');
xlabel('Chip index within codeword'); ylabel('Symbol / codeword number');
subplot(2,1,2);
imagesc(Q_path_mapped_biOrthogonal); colormap(gray); colorbar;
title({'STAGE 2b: Q path — bi-orthogonal codewords (one row per data symbol)', ...
       'Bright = chip value +1, Dark = chip value -1. This is the "Symbol Mapper" + "Interleaver" output'});
xlabel('Chip index within codeword'); ylabel('Symbol / codeword number');

%% ------------------------------------------------------------------
%  STEP 5 : PLOT THE QPSK MAPPER OUTPUT (constellation!)
%  ------------------------------------------------------------------
%  DQPSK_input is the complex symbol stream BEFORE differential encoding,
%  i.e. straight out of the "QPSK Mapper" block, X_n in your diagram.
%  This is exactly the kind of plot you'd expect from any QPSK textbook:
%  4 dots at 45/135/225/315 degrees.
% ---------------------------------------------------------------------

figure('Name','STAGE 3 - QPSK Mapper output (X_n) constellation','Color','w');
subplot(1,2,1);
plot(real(DQPSK_input), imag(DQPSK_input), 'bo', 'MarkerFaceColor','b','MarkerSize',6);
grid on; axis equal; xlim([-1.5 1.5]); ylim([-1.5 1.5]);
xlabel('In-phase (I)'); ylabel('Quadrature (Q)');
title('STAGE 3a: QPSK constellation (X_n) — should show 4 clusters at the corners');
line([-1.5 1.5],[0 0],'Color','k','LineStyle',':');
line([0 0],[-1.5 1.5],'Color','k','LineStyle',':');

subplot(1,2,2);
plot(real(DQPSK_input),'b-o','MarkerSize',3); hold on;
plot(imag(DQPSK_input),'r-o','MarkerSize',3); hold off;
grid on; legend('I (real)','Q (imag)');
title({'STAGE 3b: X_n vs symbol index (time view)', ...
       'X_n = the QPSK Mapper output, BEFORE the DQPSK differential encoder (Sn = Xn * Sn-4)'});
xlabel('Symbol index n'); ylabel('Amplitude');

%% ------------------------------------------------------------------
%  STEP 6 : COMPARE X_n (QPSK) vs S_n (after DQPSK differential coding)
%  ------------------------------------------------------------------
%  This is the single most confusing block for newcomers, so we plot
%  BEFORE and AFTER side by side. Re-derive S_n here purely for plotting/
%  teaching purposes (same math as inside ChirpSpreadSpectrum_Tx.m) so you
%  can see the differential relationship explicitly.
% ---------------------------------------------------------------------

Xn = DQPSK_input;
feedback_memory = ones(4,1) + 1i*ones(4,1);   % Sn-4 initial value = exp(j*pi/4) (unnormalized)
Sn = zeros(size(Xn));
for i = 1:4:length(Xn)-3
    Sn(i:i+3) = Xn(i:i+3) .* feedback_memory;   % Sn = Xn * Sn-4   <-- the diagram's feedback multiplier
    feedback_memory = Sn(i:i+3);                % feed this block's output into next block's Sn-4 input
end

figure('Name','STAGE 4 - DQPSK differential coding: Xn vs Sn','Color','w');
subplot(1,2,1);
plot(real(Xn), imag(Xn), 'bo', 'MarkerFaceColor','b'); grid on; axis equal;
xlim([-3 3]); ylim([-3 3]);
title('BEFORE: X_n (QPSK Mapper output)');
xlabel('I'); ylabel('Q');

subplot(1,2,2);
plot(real(Sn), imag(Sn), 'ro', 'MarkerFaceColor','r'); grid on; axis equal;
xlim([-3 3]); ylim([-3 3]);
title({'AFTER: S_n (post DQPSK differential encoder)', ...
       'S_n = X_n .* S_{n-4}  <-- this is exactly the "Z^{-4}" feedback loop drawn in your diagram'});
xlabel('I'); ylabel('Q');

%% ------------------------------------------------------------------
%  STEP 7 : THE FINAL CSS SIGNAL (output of chirpModulation)
%  ------------------------------------------------------------------
%  TxchirpSequences_float = S_n multiplied onto the CSK-generated
%  subchirps, with time gaps inserted between chirp symbols. THIS is the
%  single arrow leaving the right-hand side of your block diagram, labeled
%  "CSS signal".
% ---------------------------------------------------------------------

nSamplesToShow = min(800, length(TxchirpSequences_float)); % zoom into first part; full burst can be huge
tAxis = 1:nSamplesToShow;

figure('Name','STAGE 5 - FINAL CSS OUTPUT SIGNAL (floating point)','Color','w');

subplot(3,1,1);
plot(tAxis, real(TxchirpSequences_float(tAxis)), 'b-'); hold on;
plot(tAxis, imag(TxchirpSequences_float(tAxis)), 'r-'); hold off;
grid on; legend('I (real)','Q (imag)');
title('STAGE 5a: Final CSS signal, time domain (I and Q) — floating-point reference');
xlabel('Sample index'); ylabel('Amplitude');

subplot(3,1,2);
plot(tAxis, abs(TxchirpSequences_float(tAxis)), 'k-','LineWidth',1.2);
grid on;
title('STAGE 5b: |CSS signal| envelope — notice the GAPS between chirp bursts (Tgap)');
xlabel('Sample index'); ylabel('|Amplitude|');

subplot(3,1,3);
instPhase = unwrap(angle(TxchirpSequences_float(tAxis)));
instFreqMHz = diff(instPhase) / (2*pi) * samplingFreqMhz;
plot(instFreqMHz, 'm-','LineWidth',1.1);
grid on;
title('STAGE 5c: Instantaneous frequency of final CSS signal (the actual transmitted chirp sweep)');
xlabel('Sample index'); ylabel('Frequency (MHz, relative)');

fprintf('=========================================================\n');
fprintf(' FLOATING-POINT WALKTHROUGH COMPLETE. %d figures generated.\n', 6);
fprintf(' Next: run GUIDE_02_fixedPointConversion.m to see how this exact\n');
fprintf(' same signal flow gets quantized to fixed-point, and how MSE is\n');
fprintf(' measured against THIS floating-point output as the golden ref.\n');
fprintf('=========================================================\n');

