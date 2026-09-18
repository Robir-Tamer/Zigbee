%% ========================================================================
%  SymbolMapper_Stage_Output.m  (FIXED: zero-length payload case)
%  Generates the Symbol Mapper stage output -- BEFORE the Interleaver
%  (250 kb/s) -- one row per symbol, each row concatenating the I-path
%  (even bits) codeword directly followed by the Q-path (odd bits)
%  codeword, no separator:
%     1 Mb/s   : 8 bits/row  = 4 (I codeword) + 4 (Q codeword)
%     250 kb/s : 64 bits/row = 32 (I codeword) + 32 (Q codeword)
%
%  FIX: removed the incorrect "if paddingBy==N, paddingBy=0" special case
%  (same root cause and fix as the Zero Padding script -- see its header
%  comment for the full explanation).
%
%  Outputs:
%     ./Golden_out/1Mbps/03_symbolmapper_output_1M.txt
%     ./Golden_out/250Kbps/03_symbolmapper_output_250K.txt
%
%  Stimulus: payload.txt
% =========================================================================

clc; clear all; close all;
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' SYMBOL MAPPER STAGE OUTPUT (PRE-INTERLEAVER)\n');
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
%           Symbol Mapper exactly, write serialized rows
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz PHRlength numBitsPerCodeWordStd ...
       codeWordLengthStd codeword_1Mbs codeword_250kbs
chirpIndex = 1;

outFiles   = {'./Golden_out/1Mbps/03_symbolmapper_output_1M.txt', './Golden_out/250Kbps/03_symbolmapper_output_250K.txt'};
rateLabels = {'1 Mb/s (dataRate=0)', '250 kb/s (dataRate=1)'};

for dataRate = 0:1

    globalSettings();

    numBitsPerCodeWord = numBitsPerCodeWordStd(dataRate+1);
    codeWordLength      = codeWordLengthStd(dataRate+1);
    if dataRate == 0
        codeword = codeword_1Mbs;
    else
        codeword = codeword_250kbs;
    end

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
    if dataRate == 0
        N = numBitsPerCodeWord * 2;        % 6 for 1 Mb/s
    else
        N = numBitsPerCodeWord * 2 * 2;    % 24 for 250 kb/s
    end

    % FIXED: no special-case override -- always add N - mod(x,N) bits.
    paddingBy = N - mod(length(binaryData), N);
    binaryData = [binaryData, zeros(1,paddingBy)];

    %% ---- Demux (I = even-indexed/odd positions per original code
    %       convention, Q = odd-indexed) ----
    I = binaryData(1:2:end-1);
    Q = binaryData(2:2:end);

    %% ---- Serial-to-Parallel + Symbol Mapper lookup ----
    numCodeWords = length(binaryData)/2/numBitsPerCodeWord;

    I_path = reshape(I, numBitsPerCodeWord, numCodeWords)';
    Q_path = reshape(Q, numBitsPerCodeWord, numCodeWords)';

    I_path_dec = binary2decimal(I_path, numBitsPerCodeWord, numCodeWords);
    Q_path_dec = binary2decimal(Q_path, numBitsPerCodeWord, numCodeWords);

    I_mapped = codeword(I_path_dec+1, :);   % bipolar +1/-1, numCodeWords x codeWordLength
    Q_mapped = codeword(Q_path_dec+1, :);

    % Convert bipolar to logical bits for file output
    I_mapped01 = (I_mapped + 1) / 2;
    Q_mapped01 = (Q_mapped + 1) / 2;

    fprintf('--- %s ---\n', rateLabels{dataRate+1});
    fprintf('  Padding modulus (N)      : %d bits\n', N);
    fprintf('  Padding bits added       : %d bits\n', paddingBy);
    fprintf('  Number of symbols (rows) : %d\n', numCodeWords);
    fprintf('  Codeword length          : %d bits (I) + %d bits (Q) = %d bits/row\n\n', ...
        codeWordLength, codeWordLength, 2*codeWordLength);

    %% ---------------------------------------------------------------
    %  STEP 2: Write output -- each row = I-codeword bits then Q-codeword
    %  bits, concatenated with no separator
    %  ---------------------------------------------------------------
    fname = outFiles{dataRate+1};
    fid = fopen(fname, 'wt');
    for r = 1:numCodeWords
        fprintf(fid, '%s%s\n', sprintf('%d', I_mapped01(r,:)), sprintf('%d', Q_mapped01(r,:)));
    end
    fclose(fid);

    fprintf('  Exported : %s  (%d rows, %d bits/row)\n\n', fname, numCodeWords, 2*codeWordLength);
end

fprintf('=========================================================\n');
fprintf(' DONE. Each row = I codeword (even/Real) then Q codeword\n');
fprintf(' (odd/Imag), concatenated, one row per symbol -- PRE-\n');
fprintf(' Interleaver, per data rate.\n');
fprintf('=========================================================\n');