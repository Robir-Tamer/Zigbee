%% ========================================================================
%  Interleaver_Stage_Output.m
%  Generates the SERIALIZED output of the Symbol Mapper (+ Interleaver,
%  250 kb/s only) stage, immediately before "Form PPDU". Each output line
%  contains TWO bits, concatenated with NO separator:
%     bit 1 = I path (even-indexed bits, REAL)
%     bit 2 = Q path (odd-indexed bits, IMAG)
%  in true transmission (serial) chip order -- i.e. all chips of symbol 1
%  in order, then all chips of symbol 2, etc. -- matching the
%  Parallel-to-Serial step that follows this stage in ChirpSpreadSpectrum_Tx.m.
%
%  Outputs:
%     interleaver_output_1Mbps.txt
%     interleaver_output_250kbps.txt
%
%  Stimulus: payload.txt (same file used throughout this project).
% =========================================================================

clc; clear all; close all;
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' INTERLEAVER/SYMBOL MAPPER STAGE OUTPUT -- SERIALIZED (I,Q)\n');
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
%  STEP 1: Run BOTH data rates, capture the Symbol Mapper/Interleaver
%           output matrices (I_path_mapped_biOrthogonal, Q_path_...),
%           serialize, and write out
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz I_path_mapped_biOrthogonal Q_path_mapped_biOrthogonal
chirpIndex = 1;

outFiles   = {'./Golden_out/1Mbps/04_interleaver_output_1M.txt', './Golden_out/250Kbps/04_interleaver_output_250K.txt'};
rateLabels = {'1 Mb/s (dataRate=0)', '250 kb/s (dataRate=1)'};

for dataRate = 0:1

    globalSettings();

    chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
    close(gcf);

    % Run the real chain. I_path_mapped_biOrthogonal / Q_path_mapped_biOrthogonal
    % are captured as globals -- for 1 Mb/s this is the transposed Symbol
    % Mapper output (chips x symbols, no interleaving per spec); for
    % 250 kb/s this is the Interleaver's actual output (64 x symbolPairs).
    ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_float);

    % Serialize via column-major linear indexing: this reads all chips of
    % symbol 1 in order, then all chips of symbol 2, etc. -- exactly the
    % serial transmission order the Parallel-to-Serial step produces next.
    I_bits = I_path_mapped_biOrthogonal(:);   % bipolar +1/-1
    Q_bits = Q_path_mapped_biOrthogonal(:);

    % Convert bipolar (+1/-1) chips to logical bits (1/0) for file output.
    I_bits01 = (I_bits + 1) / 2;
    Q_bits01 = (Q_bits + 1) / 2;

    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  I path serialized length : %d chips\n', length(I_bits01));
    fprintf('  Q path serialized length : %d chips\n\n', length(Q_bits01));

    %% ---------------------------------------------------------------
    %  STEP 2: Write output -- each line = "IQ" (two bits, no separator)
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');
    for n = 1:length(I_bits01)
        fprintf(fid, '%d%d\n', I_bits01(n), Q_bits01(n));
    end
    fclose(fid);

    fprintf('  Exported : %s  (%d lines)\n\n', fname, length(I_bits01));
end

fprintf('=========================================================\n');
fprintf(' DONE. Each line = I-bit then Q-bit (even=I=Real, odd=Q=Imag),\n');
fprintf(' serialized in true chip transmission order, per data rate.\n');
fprintf('=========================================================\n');