%% ========================================================================
%  Demux_Stage_Output.m
%  Generates the Demux stage output -- the raw bit groups AFTER
%  Zero Padding + Demux + Serial-to-Parallel, BEFORE the Symbol Mapper
%  lookup. One row per symbol-group, each row concatenating the I-path
%  (even bits) parallel group directly followed by the Q-path (odd bits)
%  parallel group, no separator:
%     1 Mb/s   : 6 bits/row  = 3 (I group) + 3 (Q group)
%     250 kb/s : 12 bits/row = 6 (I group) + 6 (Q group)
%
%  Outputs:
%     demux_output_1Mbps.txt
%     demux_output_250kbps.txt
%
%  Stimulus: payload.txt
% =========================================================================

clc; clear all; close all;
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' DEMUX STAGE OUTPUT (PARALLEL I/Q GROUPS, PRE-SYMBOL-MAPPER)\n');
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
%  STEP 1: Run BOTH data rates, replicate PHR + Zero Padding + Demux +
%           Serial-to-Parallel exactly, write parallel-group rows
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz PHRlength numBitsPerCodeWordStd
chirpIndex = 1;

outFiles   = {'./Golden_out/1Mbps/02_demux_output_1M.txt', './Golden_out/250Kbps/02_demux_output_250K.txt'};
rateLabels = {'1 Mb/s (dataRate=0)', '250 kb/s (dataRate=1)'};

for dataRate = 0:1

    globalSettings();

    numBitsPerCodeWord = numBitsPerCodeWordStd(dataRate+1);

    %% ---- PHR construction (matches ChirpSpreadSpectrum_Tx.m) ----
    payloadLength = length(incomingStream)/8;
    payloadLength_Binary = zeros(1,7);
    payloadLength_Binary(7:-1:1) = decimal2binary(payloadLength,7,1);
    PHR = [payloadLength_Binary, zeros(1, PHRlength-7)];

    binaryData = [PHR, incomingStream];

    %% ---- Zero Padding ----
    % NOTE: N is NOT the same multiplier for both data rates.
    %   1 Mb/s   : N = 2(I,Q) * numBitsPerCodeWord                          = 6
    %   250 kb/s : N = 2(I,Q) * 2(consecutive codewords) * numBitsPerCodeWord = 24
    % The interleaver for 250 kb/s spans TWO consecutive codewords, which is
    % where the extra factor of 2 comes from (see 6.5a.2.1 /
    % ChirpSpreadSpectrum_Tx.m, where paddingBy is hardcoded per rate as 6
    % and 24 respectively). Using "numBitsPerCodeWord * 2" for both rates
    % silently halves N for 250 kb/s -- this is what dropped the last
    % 12-bit (6+6) row for the 32-byte payload case.
    if dataRate == 0
        N = numBitsPerCodeWord * 2;        % 6 for 1 Mb/s
    else
        N = numBitsPerCodeWord * 2 * 2;    % 24 for 250 kb/s
    end

    paddingBy = N - mod(length(binaryData), N);
    if paddingBy == N
        paddingBy = 0;   % already aligned -- avoid adding a full spurious block
    end
    binaryData = [binaryData, zeros(1,paddingBy)];

    %% ---- Demux ----
    I = binaryData(1:2:end-1);
    Q = binaryData(2:2:end);

    %% ---- Serial-to-Parallel: reshape into parallel groups ----
    numGroups = length(binaryData)/2/numBitsPerCodeWord;

    I_path = reshape(I, numBitsPerCodeWord, numGroups)';   % numGroups x numBitsPerCodeWord
    Q_path = reshape(Q, numBitsPerCodeWord, numGroups)';

    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  Padding modulus (N)              : %d bits\n', N);
    fprintf('  Padding bits added               : %d bits\n', paddingBy);
    fprintf('  Number of parallel groups (rows) : %d\n', numGroups);
    fprintf('  Bits per path per row             : %d (I) + %d (Q) = %d bits/row\n\n', ...
        numBitsPerCodeWord, numBitsPerCodeWord, 2*numBitsPerCodeWord);

    %% ---------------------------------------------------------------
    %  STEP 2: Write output -- each row = I parallel group then Q
    %  parallel group, concatenated with no separator
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');
    for r = 1:numGroups
        fprintf(fid, '%s%s\n', sprintf('%d', I_path(r,:)), sprintf('%d', Q_path(r,:)));
    end
    fclose(fid);

    fprintf('  Exported : %s  (%d rows, %d bits/row)\n\n', fname, numGroups, 2*numBitsPerCodeWord);
end

fprintf('=========================================================\n');
fprintf(' DONE. Each row = I parallel group (even/Real) then Q\n');
fprintf(' parallel group (odd/Imag), concatenated, one row per\n');
fprintf(' symbol-group -- PRE-Symbol-Mapper, per data rate.\n');
fprintf('=========================================================\n');
