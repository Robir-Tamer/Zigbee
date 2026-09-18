%% ========================================================================
%  Generate_DQPSK_Input_Payloads.m
%  Runs the full front-end pipeline (Zero Padding -> Demux -> Symbol
%  Mapper -> Interleaver -> Form PPDU -> QPSK Mapper) on the project's
%  real payload.txt, for BOTH data rates, and exports the resulting X_n
%  (QPSK Mapper output -- the exact signal that feeds the DQPSK stage)
%  as two Verilog-testbench-ready stimulus files in 2-bit signed 2's
%  complement binary format (IIQQ):
%     QPSK_OUT_1Mbps.txt   -- 1 Mb/s   (dataRate=0)
%     QPSK_OUT_250kbps.txt -- 250 kb/s (dataRate=1)
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

outFiles   = {'./Golden_out/1Mbps/06_QPSK_OUT_1M.txt', './Golden_out/250Kbps/06_QPSK_OUT_250K.txt'};
rateLabels = {'1 Mb/s (dataRate=0)', '250 kb/s (dataRate=1)'};

for dataRate = 0:1
    globalSettings();   % fresh globals each run (Tchirp/Tsub/tables reset)
    chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
    close(gcf);
    
    % Run the real transmitter chain. DQPSK_input (X_n) is populated as a
    % global side effect.
    ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_float);
    
    Xn = DQPSK_input;
    Xn_real = real(Xn);
    Xn_imag = imag(Xn);
    
    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  Total QPSK symbols (X_n) generated : %d\n', length(Xn));
    fprintf('  Value range check: Real in {-1,0,1}? %s | Imag in {-1,0,1}? %s\n', ...
        mat2str(all(ismember(Xn_real, [-1 0 1]))), mat2str(all(ismember(Xn_imag, [-1 0 1]))));
    
    %% ---------------------------------------------------------------
    %  STEP 2: Export as 4-bit 2's complement binary strings (IIQQ)
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');
    
    % Map integers {-1, 0, 1} to 2-bit 2's complement strings
    binMap = containers.Map({-1, 0, 1}, {'11', '00', '01'});
    
    for n = 1:length(Xn)
        realStr = binMap(Xn_real(n));
        imagStr = binMap(Xn_imag(n));
        fprintf(fid, '%s%s\n', realStr, imagStr);
    end
    
    fclose(fid);
    fprintf('  Exported : %s  (%d binary lines)\n\n', fname, length(Xn));
end

fprintf('=========================================================\n');
fprintf(' DONE. Files created in unspaced 2''s complement (IIQQ)\n');
fprintf(' binary format ready for Verilog testbench ingestion.\n');
fprintf('=========================================================\n');