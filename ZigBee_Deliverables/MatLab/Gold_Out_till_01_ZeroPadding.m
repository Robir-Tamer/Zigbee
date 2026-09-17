%% ========================================================================
%  ZeroPadding_Stage_Output.m
%  Generates the Zero Padding stage output -- PHR + PSDU concatenated,
%  then padded with trailing zero bits to a multiple of N (N=6 for
%  1 Mb/s, N=24 for 250 kb/s), per 6.5a.2.1/ChirpSpreadSpectrum_Tx.m.
%  This is the raw serial bit stream immediately BEFORE the Demux stage.
%
%  Output: one bit per line (serial), for each data rate.
%     zeropadding_output_1Mbps.txt
%     zeropadding_output_250kbps.txt
%
%  Stimulus: payload.txt
% =========================================================================

clc; clear all; close all;
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' ZERO PADDING STAGE OUTPUT (PHR + PSDU + PADDING, SERIAL)\n');
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
%  STEP 1: Run BOTH data rates, replicate PHR + Zero Padding exactly
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz PHRlength numBitsPerCodeWordStd
chirpIndex = 1;

outFiles   = {'./Golden_out/1Mbps/01_zeropadding_output_1M.txt', './Golden_out/250Kbps/01_zeropadding_output_250K.txt'};
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
    prePadLength = length(binaryData);

    %% ---- Zero Padding ----
    % NOTE: N is NOT the same multiplier for both data rates.
    %   1 Mb/s   : N = 2(I,Q) * numBitsPerCodeWord                     = 6
    %   250 kb/s : N = 2(I,Q) * 2(consecutive codewords) * numBitsPerCodeWord = 24
    % The interleaver for 250 kb/s spans TWO consecutive codewords, which
    % is where the extra factor of 2 comes from (see 6.5a.2.1 /
    % ChirpSpreadSpectrum_Tx.m, where paddingBy is hardcoded per rate as
    % 6 and 24 respectively). Using the same "numBitsPerCodeWord * 2" for
    % both rates silently halves N for 250 kb/s and produces a stream
    % that is NOT a multiple of 24, which is what caused the RTL/MATLAB
    % mismatch after the PHR+PSDU boundary.
    if dataRate == 0
        N = numBitsPerCodeWord * 2;        % 6 for 1 Mb/s
    else
        N = numBitsPerCodeWord * 2 * 2;    % 24 for 250 kb/s
    end

    paddingBy = N - mod(prePadLength, N);
    if paddingBy == N
        paddingBy = 0;   % already aligned -- avoid adding a full spurious block
    end
    binaryData = [binaryData, zeros(1,paddingBy)];

    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  PHR length            : %d bits\n', PHRlength);
    fprintf('  PSDU length           : %d bits\n', length(incomingStream));
    fprintf('  PHR+PSDU (pre-pad)    : %d bits\n', prePadLength);
    fprintf('  Padding modulus (N)   : %d bits\n', N);
    fprintf('  Padding bits added    : %d bits\n', paddingBy);
    fprintf('  Total padded length   : %d bits\n\n', length(binaryData));

    %% ---------------------------------------------------------------
    %  STEP 2: Write output -- one bit per line, serial order
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');
    for n = 1:length(binaryData)
        fprintf(fid, '%d\n', binaryData(n));
    end
    fclose(fid);

    fprintf('  Exported : %s  (%d bits)\n\n', fname, length(binaryData));
end

fprintf('=========================================================\n');
fprintf(' DONE. Each file is the full PHR+PSDU+padding serial bit\n');
fprintf(' stream, immediately BEFORE the Demux stage, per data rate.\n');
fprintf('=========================================================\n');
