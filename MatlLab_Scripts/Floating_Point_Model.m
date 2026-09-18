%% ========================================================================
%  GUIDE 01 : FLOATING-POINT CSS TRANSMITTER -- GUIDED WALKTHROUGH
%             STIMULUS: payload.txt
%  =========================================================================
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);

addpath('common');
addpath('transmitter');

fprintf('\n');
fprintf('=========================================================\n');
fprintf(' GUIDE 01 : FLOATING-POINT CSS TRANSMITTER WALKTHROUGH\n');
fprintf(' STIMULUS: payload.txt\n');
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0 : CONFIGURATION
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz carrierFreqGHz codeWordLengthStd ...
       preambleLengthStd Tchirp Tsub TxDACbitNumber ...
       chirpSequenceNumBit_Rx TxChirpSequencesLength SFD_Std SFDlength ...
       PHRlength numBitsPerCodeWordStd codeword_1Mbs codeword_250kbs

chirpIndex   = 1;
dataRate     = 0;      % 0 = 1 Mb/s, 1 = 250 kb/s

globalSettings();

if dataRate==0
    rateStr = '1 Mb/s';
else
    rateStr = '250 kb/s';
end

%% ------------------------------------------------------------------
%  STEP 0b : STIMULUS -- load payload.txt
%  ------------------------------------------------------------------
fid = fopen('payload.txt', 'rt');
if fid == -1
    error('payload.txt not found on path.');
end
payloadLines = {};
tline = fgetl(fid);
while ischar(tline)
    if ~isempty(tline)
        payloadLines{end+1} = tline; %#ok<AGROW>
    end
    tline = fgetl(fid);
end
fclose(fid);

numPayloadBytes = length(payloadLines);
incomingStream = zeros(1, numPayloadBytes*8);
for b = 1:numPayloadBytes
    byteBits = payloadLines{b} - '0';
    incomingStream((b-1)*8+1 : b*8) = byteBits;
end

fprintf('Configuration:\n');
fprintf('  Data rate           : %s\n', rateStr);
fprintf('  Chirp index (m)     : %d\n', chirpIndex);
fprintf('  Sampling frequency  : %d MHz\n', samplingFreqMhz);
fprintf('  Carrier frequency   : %.2f GHz\n', carrierFreqGHz);
fprintf('  Payload length      : %d bytes (%d bits, from payload.txt)\n', numPayloadBytes, numPayloadBytes*8);
fprintf('  Tchirp (chirp len)  : %d samples\n', Tchirp);
fprintf('  Tsub (subchirp len) : %d samples\n\n', Tsub);

figure('Name','STAGE 0 - Raw Input Bitstream','Color','w');
stem(incomingStream, 'filled', 'MarkerSize', 4);
ylim([-0.2 1.2]);
grid on;
title({sprintf('STAGE 0: Raw payload bits from payload.txt (%d bytes) -- the PSDU going INTO the PHR builder', numPayloadBytes), ...
       'This is the "PHR and PSDU" arrow entering "Zero Padding" in your block diagram'});
xlabel('Bit index'); ylabel('Bit value');

%% ------------------------------------------------------------------
%  STEP 2 : GENERATE THE CHIRP SEQUENCE (the CSK Generator block)
%  ------------------------------------------------------------------
chirpSequence = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);

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
global I_path_mapped_biOrthogonal Q_path_mapped_biOrthogonal DQPSK_input

TxchirpSequences_float = ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence);

fprintf('Transmitter run complete.\n');
fprintf('  Output CSS signal length : %d complex samples\n\n', length(TxchirpSequences_float));

%% ------------------------------------------------------------------
%  STEP 4 : PLOT THE SYMBOL MAPPER + INTERLEAVER OUTPUT (I and Q)
%  ------------------------------------------------------------------
figure('Name','STAGE 2 - Symbol Mapper / Interleaver output (I & Q)','Color','w');
subplot(2,1,1);
imagesc(I_path_mapped_biOrthogonal); colormap(gray); colorbar;
title('STAGE 2a: I path -- bi-orthogonal codewords (one row per data symbol)');
xlabel('Chip index within codeword'); ylabel('Symbol / codeword number');
subplot(2,1,2);
imagesc(Q_path_mapped_biOrthogonal); colormap(gray); colorbar;
title({'STAGE 2b: Q path -- bi-orthogonal codewords (one row per data symbol)', ...
       'Bright = chip value +1, Dark = chip value -1. This is the "Symbol Mapper" + "Interleaver" output'});
xlabel('Chip index within codeword'); ylabel('Symbol / codeword number');

%% ------------------------------------------------------------------
%  STEP 5 : PLOT THE QPSK MAPPER OUTPUT (constellation!)
%  ------------------------------------------------------------------
figure('Name','STAGE 3 - QPSK Mapper output (X_n) constellation','Color','w');
subplot(1,2,1);
plot(real(DQPSK_input), imag(DQPSK_input), 'bo', 'MarkerFaceColor','b','MarkerSize',6);
grid on; axis equal; xlim([-1.5 1.5]); ylim([-1.5 1.5]);
xlabel('In-phase (I)'); ylabel('Quadrature (Q)');
title('STAGE 3a: QPSK constellation (X_n) -- should show 4 clusters at the corners');
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
Xn = DQPSK_input;
feedback_memory = ones(4,1) + 1i*ones(4,1);
Sn = zeros(size(Xn));
for i = 1:4:length(Xn)-3
    Sn(i:i+3) = Xn(i:i+3) .* feedback_memory;
    feedback_memory = Sn(i:i+3);
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
nSamplesToShow = min(800, length(TxchirpSequences_float));
tAxis = 1:nSamplesToShow;

figure('Name','STAGE 5 - FINAL CSS OUTPUT SIGNAL (floating point)','Color','w');

subplot(3,1,1);
plot(tAxis, real(TxchirpSequences_float(tAxis)), 'b-'); hold on;
plot(tAxis, imag(TxchirpSequences_float(tAxis)), 'r-'); hold off;
grid on; legend('I (real)','Q (imag)');
title('STAGE 5a: Final CSS signal, time domain (I and Q) -- floating-point reference');
xlabel('Sample index'); ylabel('Amplitude');

subplot(3,1,2);
plot(tAxis, abs(TxchirpSequences_float(tAxis)), 'k-','LineWidth',1.2);
grid on;
title('STAGE 5b: |CSS signal| envelope -- notice the GAPS between chirp bursts (Tgap)');
xlabel('Sample index'); ylabel('|Amplitude|');

subplot(3,1,3);
instPhase = unwrap(angle(TxchirpSequences_float(tAxis)));
instFreqMHz = diff(instPhase) / (2*pi) * samplingFreqMhz;
plot(instFreqMHz, 'm-','LineWidth',1.1);
grid on;
title('STAGE 5c: Instantaneous frequency of final CSS signal (the actual transmitted chirp sweep)');
xlabel('Sample index'); ylabel('Frequency (MHz, relative)');

fprintf('=========================================================\n');
fprintf(' FLOATING-POINT WALKTHROUGH COMPLETE (payload.txt stimulus).\n');
fprintf('=========================================================\n');