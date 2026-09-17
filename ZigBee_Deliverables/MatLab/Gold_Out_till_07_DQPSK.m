%% ========================================================================
%  Generate_DQPSK_Stage_Output.m
%  Generates the golden reference output directly AFTER the DQPSK differential
%  encoder stage for both data rates using payload.txt as stimulus.
%
%  Output format: Each row contains 4 bits (no spaces):
%    - Bits [3:2] : Real part in 2-bit signed 2's complement
%    - Bits [1:0] : Imag part in 2-bit signed 2's complement
%
%  Mapping:
%     1  -> 01
%     0  -> 00
%    -1  -> 11
%
%  Outputs:
%     dqpsk_output_1Mbps.txt   -- 1 Mb/s   (dataRate=0)
%     dqpsk_output_250kbps.txt -- 250 kb/s (dataRate=1)
% =========================================================================

clc; clear all; close all;
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' GENERATING DQPSK STAGE OUTPUT (2-BIT 2''S COMPLEMENT IIQQ)\n');
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
    if ~isempty(strtrim(tline))
        payloadLines{end+1} = strtrim(tline); %#ok<AGROW>
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
%  STEP 1: Run transmitter pipeline up through DQPSK for BOTH rates
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz DQPSK_input
chirpIndex = 1;

outFiles   = {'./Golden_out/1Mbps/07_DQPSK_OUT_1M.txt', './Golden_out/250Kbps/07_DQPSK_OUT_250K.txt'};

rateLabels = {'1 Mb/s (dataRate=0)', '250 kb/s (dataRate=1)'};

% Lookup map for signed values -> 2-bit 2's complement
binMap = containers.Map({-1, 0, 1}, {'11', '00', '01'});

for dataRate = 0:1
    globalSettings();
    chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
    if ishandle(gcf)
        close(gcf);
    end

    % Run transmitter function
    ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_float);

    % Retrieve DQPSK_input populated globally by ChirpSpreadSpectrum_Tx
    if ~exist('DQPSK_input', 'var') || isempty(DQPSK_input)
        error('DQPSK_input global variable was not populated by ChirpSpreadSpectrum_Tx.');
    end

    % Recompute differential encoding matching ChirpSpreadSpectrum_Tx exactly
    feedback_memory = ones(4,1) + 1i*ones(4,1);
    numDQPSKinputs  = length(DQPSK_input);
    dqpsk_syms      = zeros(numDQPSKinputs, 1);

    for i = 1 : 4 : numDQPSKinputs
        dqpsk_syms(i:i+3, 1) = DQPSK_input(i:i+3, 1) .* feedback_memory;
        feedback_memory       = dqpsk_syms(i:i+3, 1);
    end

    dqpsk_real = real(dqpsk_syms);
    dqpsk_imag = imag(dqpsk_syms);

    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  Total DQPSK symbols generated : %d\n', length(dqpsk_syms));
    fprintf('  Value range check: Real in {-1,0,1}? %s | Imag in {-1,0,1}? %s\n', ...
        mat2str(all(ismember(dqpsk_real, [-1 0 1]))), ...
        mat2str(all(ismember(dqpsk_imag, [-1 0 1]))));

    %% ---------------------------------------------------------------
    %  STEP 2: Write 4-bit IIQQ strings to output file
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');

    for n = 1:length(dqpsk_syms)
        rStr = binMap(dqpsk_real(n));
        iStr = binMap(dqpsk_imag(n));
        fprintf(fid, '%s%s\n', rStr, iStr);
    end
    fclose(fid);

    fprintf('  Exported : %s  (%d lines, 4 bits/line)\n\n', fname, length(dqpsk_syms));
end

fprintf('=========================================================\n');
fprintf(' DONE. Files created containing 4-bit 2''s complement\n');
fprintf(' (IIQQ) representations directly output from DQPSK.\n');
fprintf('=========================================================\n');