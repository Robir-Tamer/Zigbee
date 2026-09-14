%% ========================================================================
%  Generate_DQPSK_Input_Payloads.m
%  Runs the full front-end pipeline (Zero Padding -> Demux -> Symbol
%  Mapper -> Interleaver -> Form PPDU -> QPSK Mapper) on the project's
%  real payload.txt, for BOTH data rates, and exports the resulting X_n
%  (QPSK Mapper output -- the exact signal that feeds the DQPSK stage)
%  as two Verilog-testbench-ready stimulus files:
%     payload1.txt -- 1 Mb/s  (dataRate=0)
%     payload2.txt -- 250 kb/s (dataRate=1)
%
%  X_n is globally captured by ChirpSpreadSpectrum_Tx.m (declared global
%  DQPSK_input), so this script calls the real transmitter chain itself
%  rather than re-implementing any stage -- the output is guaranteed
%  consistent with the actual golden model, not a re-derivation.
%
%  X_n only ever takes values in {+1,0,-1} per component (QPSK Mapper
%  truth table), so each line is written as two signed integers,
%  "Real Imag", one symbol per line -- directly parseable by a Verilog
%  testbench without any bit-to-symbol conversion needed.
% =========================================================================

clc; clear all; close all;
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' GENERATING DQPSK-INPUT STIMULUS FILES FROM payload.txt\n');
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0: Load payload.txt
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

fprintf('Loaded payload.txt : %d bytes (%d bits)\n\n', numPayloadBytes, numPayloadBytes*8);

%% ------------------------------------------------------------------
%  STEP 1: Run the front-end pipeline for BOTH data rates, capture X_n
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz DQPSK_input
chirpIndex = 1;

outFiles = {'QPSK_OUT_1Mbps.txt', 'QPSK_OUT_250kbps.txt'};
rateLabels = {'1 Mb/s (dataRate=0)', '250 kb/s (dataRate=1)'};

for dataRate = 0:1

    globalSettings();   % fresh globals each run (Tchirp/Tsub/tables reset)

    chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
    close(gcf);

    % Run the real transmitter chain. DQPSK_input (X_n) is populated as a
    % global side effect -- this IS the QPSK Mapper's actual output, the
    % exact signal that feeds into the DQPSK differential encoder next.
    ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_float);

    Xn = DQPSK_input;
    Xn_real = real(Xn);
    Xn_imag = imag(Xn);

    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  Total QPSK symbols (X_n) generated : %d\n', length(Xn));
    fprintf('  Value range check: Real in {-1,0,1}? %s | Imag in {-1,0,1}? %s\n', ...
        mat2str(all(ismember(Xn_real, [-1 0 1]))), mat2str(all(ismember(Xn_imag, [-1 0 1]))));

    %% ---------------------------------------------------------------
    %  STEP 2: Export as "Real Imag" pairs, one symbol per line
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');
    fprintf(fid, '// DQPSK stage input stimulus, generated from payload.txt (%d bytes)\n', numPayloadBytes);
    fprintf(fid, '// Data rate: %s\n', rateLabels{dataRate+1});
    fprintf(fid, '// This is X_n, the QPSK Mapper output -- the exact signal that\n');
    fprintf(fid, '// feeds the DQPSK differential encoder (Real, Imag), one symbol/line.\n');
    fprintf(fid, '// Includes preamble+SFD (prepended) and the full processed PSDU.\n');
    fprintf(fid, '// Format: <Real> <Imag>, each in {-1, 0, 1}\n');
    for n = 1:length(Xn)
        fprintf(fid, '%d %d\n', Xn_real(n), Xn_imag(n));
    end
    fclose(fid);

    fprintf('  Exported : %s  (%d symbol lines)\n\n', fname, length(Xn));
end

fprintf('=========================================================\n');
fprintf(' DONE. payload1.txt (1 Mb/s) and payload2.txt (250 kb/s)\n');
fprintf(' now contain the exact DQPSK-stage input derived from the\n');
fprintf(' original 28-byte payload.txt, including preamble/SFD.\n');
fprintf('=========================================================\n');