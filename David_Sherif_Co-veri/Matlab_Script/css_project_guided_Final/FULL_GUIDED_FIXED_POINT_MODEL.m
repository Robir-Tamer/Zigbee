%% ========================================================================
%  GUIDE : FULL DUAL-RATE FIXED-POINT MODEL -- ALL STAGES
%          CHIRP ROM = Q1.4 (WL=6), OUTPUT = Q3.4 (WL=8)
%          STIMULUS: payload.txt | EXPORTS: tx_real/tx_imag Q3.4 files,
%                    preamble+SFD bipolar files (both data rates)
%  =========================================================================
%  Formats:
%    CHIRP ROM   : Q1.4 = numerictype(1,6,4) -- 1 sign+1 int+4 frac, WL=6
%    tx_real/imag: Q3.4 = numerictype(1,8,4) -- 1 sign+3 int+4 frac, WL=8
%
%  Two-stage quantization: ROM quantized to Q1.4 FIRST, fed into the
%  transmitter chain, THEN final output quantized to Q3.4 -- models both
%  real hardware quantization points, not a single one-shot approximation.
%
%  Every stage is shown for BOTH data rates, clearly labeled and separated.
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);
addpath('common'); addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' FULL GUIDED MODEL: ROM=Q1.4(WL=6) -> OUTPUT=Q3.4(WL=8)\n');
fprintf(' STIMULUS: payload.txt | BOTH DATA RATES | ALL STAGES\n');
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0 : LOCK IN BOTH FIXED-POINT FORMATS
%  ------------------------------------------------------------------
T_rom = numerictype(1, 6, 4);     % Q1.4, chirp ROM samples
F_rom = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');

T_out = numerictype(1, 8, 4);     % Q3.4, tx_real / tx_imag
F_out = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');

fprintf('--- Locked-in fixed-point formats ---\n');
fprintf('  Chirp ROM samples   : Q1.4  numerictype(1,6,4)  -- 1 sign+1 int+4 frac, WL=6\n');
fprintf('  tx_real / tx_imag   : Q3.4  numerictype(1,8,4)  -- 1 sign+3 int+4 frac, WL=8\n\n');

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

fprintf('--- Stimulus loaded from payload.txt ---\n');
fprintf('  Payload length : %d bytes (%d bits)\n\n', numPayloadBytes, numPayloadBytes*8);

figure('Name','STAGE 0 - Input Payload Bitstream','Color','w','Position',[50 50 1200 300]);
stem(incomingStream, 'filled', 'MarkerSize', 3);
ylim([-0.3 1.3]); grid on;
title(sprintf('STAGE 0: Raw payload bits from payload.txt (%d bytes, %d bits) -- shared by both data rates', ...
    numPayloadBytes, numPayloadBytes*8));
xlabel('Bit index'); ylabel('Bit value');

%% ========================================================================
%  MAIN LOOP: BOTH DATA RATES
%  ========================================================================
rateLabels = {'1 Mb/s', '250 kb/s'};
TxFloatAll = cell(1,2);
TxOutAll   = cell(1,2);
mseAll     = zeros(1,2);
romMSEAll  = zeros(1,2);

global chirpIndex samplingFreqMhz carrierFreqGHz Tchirp Tsub ...
       preambleLengthStd SFDlength SFD_Std

for dataRate = 0:1

    rateName = rateLabels{dataRate+1};
    fprintf('\n#########################################################\n');
    fprintf('#  RUNNING DATA RATE: %s  (dataRate = %d)\n', rateName, dataRate);
    fprintf('#########################################################\n\n');

    chirpIndex = 1;
    globalSettings();

    rateTag = strrep(rateName, ' ', '');
    rateTag = strrep(rateTag, '/', '');

    %% -------------------------------------------------------------
    %  STAGE 0c : GENERATE + EXPORT PREAMBLE AND SFD (bipolar +-1)
    %  -------------------------------------------------------------
    preambleLength = preambleLengthStd(dataRate+1);
    preamble       = ones(1, preambleLength);
    SFD            = SFD_Std(dataRate+1, :);
    preamble_SFD   = [preamble, SFD];

    fprintf('--- STAGE 0c: Preamble + SFD generation [%s] ---\n', rateName);
    fprintf('  Preamble length : %d chirp symbols (all +1)\n', preambleLength);
    fprintf('  SFD length      : %d chips\n', SFDlength);
    fprintf('  Combined length : %d chips (applied identically to I and Q)\n\n', length(preamble_SFD));

    fnamePreSFD = sprintf('preamble_SFD_%s.txt', rateTag);
    fidPS = fopen(fnamePreSFD, 'wt');
    fprintf(fidPS, '// Preamble + SFD, bipolar +-1, data rate %s\n', rateName);
    fprintf(fidPS, '// First %d entries = preamble (all +1), last %d entries = SFD\n', ...
        preambleLength, SFDlength);
    fprintf(fidPS, '// Applied identically to BOTH I and Q inputs of the QPSK mapper\n');
    for n = 1:length(preamble_SFD)
        fprintf(fidPS, '%d\n', preamble_SFD(n));
    end
    fclose(fidPS);
    fprintf('  Exported : %s  (%d entries)\n\n', fnamePreSFD, length(preamble_SFD));

    figure('Name',sprintf('STAGE 0c - Preamble+SFD [%s]',rateName),'Color','w','Position',[50 50 1100 350]);
    stem(preamble_SFD, 'filled', 'MarkerSize',4);
    hold on;
    line([preambleLength+0.5 preambleLength+0.5], [-1.5 1.5], 'Color','r','LineStyle','--','LineWidth',1.5);
    hold off;
    ylim([-1.5 1.5]); grid on;
    title(sprintf('STAGE 0c [%s]: Preamble (left of red line) + SFD (right of red line), bipolar +-1',rateName));
    xlabel('Chip index'); ylabel('Value');

    %% -------------------------------------------------------------
    %  STAGE 1 : CSK GENERATOR -- FLOAT, THEN QUANTIZE TO Q1.4
    %  -------------------------------------------------------------
    chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
    close(gcf);

    chirpSequence_q14 = fi(chirpSequence_float, T_rom, F_rom);

    romErrNum   = sum(abs(chirpSequence_float(:) - double(chirpSequence_q14(:))).^2);
    romErrDenom = sum(abs(chirpSequence_float(:)).^2);
    romMSE      = romErrNum / romErrDenom;
    romMSEAll(dataRate+1) = romMSE;

    fprintf('--- STAGE 1: CSK Generator, ROM quantized to Q1.4 [%s] ---\n', rateName);
    fprintf('  Chirp sequence size : %d x %d subchirps\n', size(chirpSequence_float,1), size(chirpSequence_float,2));
    fprintf('  ROM-only MSE (Q1.4) : %.8f\n\n', romMSE);

    figure('Name',sprintf('STAGE 1 - CSK ROM: float vs Q1.4 [%s]',rateName),'Color','w','Position',[50 50 1100 700]);
    subplot(2,1,1);
    p1=plot(real(chirpSequence_float(:,1)),'b-','LineWidth',1.6); hold on;
    p2=plot(real(double(chirpSequence_q14(:,1))),'r.-','LineWidth',1,'MarkerSize',10); hold off;
    grid on; legend([p1 p2],{'Floating point (golden)','Q1.4 quantized ROM'},'Location','best');
    title(sprintf('STAGE 1a [%s]: REAL part, subchirp k=1 -- ROM MSE=%.6f',rateName,romMSE));
    xlabel('Sample index'); ylabel('Amplitude');
    subplot(2,1,2);
    romErrSig = real(chirpSequence_float(:,1)) - real(double(chirpSequence_q14(:,1)));
    plot(romErrSig,'k-','LineWidth',1.2); hold on;
    line([1 length(romErrSig)],[2^-4/2 2^-4/2],'Color','g','LineStyle','--');
    line([1 length(romErrSig)],[-2^-4/2 -2^-4/2],'Color','g','LineStyle','--');
    hold off; grid on;
    title(sprintf('STAGE 1b [%s]: ROM quantization error, +-0.5 LSB bound',rateName));
    xlabel('Sample index'); ylabel('Error');

    %% -------------------------------------------------------------
    %  STAGE 2 : RUN FULL TRANSMITTER USING Q1.4-QUANTIZED ROM
    %  -------------------------------------------------------------
    chirpSequence_forTx = double(chirpSequence_q14);

    global I_path_mapped_biOrthogonal Q_path_mapped_biOrthogonal DQPSK_input
    TxchirpSequences_float = ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_forTx);

    fprintf('--- STAGE 2: Full transmitter run [%s] ---\n', rateName);
    fprintf('  Final CSS signal length : %d complex samples\n\n', length(TxchirpSequences_float));

    %% -------------------------------------------------------------
    %  STAGE 3 : SYMBOL MAPPER / INTERLEAVER OUTPUT (I & Q)
    %  -------------------------------------------------------------
    if dataRate==1, ilTag=' + Interleaver'; else, ilTag=''; end
    fprintf('--- STAGE 3: Symbol Mapper%s output [%s] ---\n', ilTag, rateName);
    fprintf('  I path size : %d x %d | Q path size : %d x %d\n\n', ...
        size(I_path_mapped_biOrthogonal,1), size(I_path_mapped_biOrthogonal,2), ...
        size(Q_path_mapped_biOrthogonal,1), size(Q_path_mapped_biOrthogonal,2));

    figure('Name',sprintf('STAGE 3 - Symbol Mapper%s [%s]',ilTag,rateName),'Color','w','Position',[50 50 1000 600]);
    subplot(2,1,1); imagesc(I_path_mapped_biOrthogonal); colormap(gray); colorbar;
    title(sprintf('STAGE 3a [%s]: I path chips -- bright=+1, dark=-1',rateName));
    xlabel('Chip index'); ylabel('Symbol index');
    subplot(2,1,2); imagesc(Q_path_mapped_biOrthogonal); colormap(gray); colorbar;
    title(sprintf('STAGE 3b [%s]: Q path chips',rateName));
    xlabel('Chip index'); ylabel('Symbol index');

    %% -------------------------------------------------------------
    %  STAGE 4 : QPSK MAPPER OUTPUT (X_n constellation)
    %  -------------------------------------------------------------
    fprintf('--- STAGE 4: QPSK Mapper output [%s] ---\n', rateName);
    fprintf('  X_n length : %d complex symbols\n\n', length(DQPSK_input));

    figure('Name',sprintf('STAGE 4 - QPSK Mapper [%s]',rateName),'Color','w','Position',[50 50 900 450]);
    plot(real(DQPSK_input),imag(DQPSK_input),'bo','MarkerFaceColor','b','MarkerSize',6);
    grid on; axis equal; xlim([-1.5 1.5]); ylim([-1.5 1.5]);
    title(sprintf('STAGE 4 [%s]: QPSK constellation (X_n)',rateName));
    xlabel('I'); ylabel('Q');
    line([-1.5 1.5],[0 0],'Color','k','LineStyle',':');
    line([0 0],[-1.5 1.5],'Color','k','LineStyle',':');

    %% -------------------------------------------------------------
    %  STAGE 5 : DQPSK DIFFERENTIAL CODING (X_n vs S_n)
    %  -------------------------------------------------------------
    Xn = DQPSK_input;
    fb = ones(4,1) + 1i*ones(4,1);
    Sn = zeros(size(Xn));
    for i = 1:4:length(Xn)-3
        Sn(i:i+3) = Xn(i:i+3) .* fb;
        fb = Sn(i:i+3);
    end
    fprintf('--- STAGE 5: DQPSK differential coding [%s] ---\n', rateName);
    fprintf('  S_n length : %d | Max |S_n| : %.4f\n\n', length(Sn), max(abs(Sn)));

    figure('Name',sprintf('STAGE 5 - DQPSK: Xn vs Sn [%s]',rateName),'Color','w','Position',[50 50 900 450]);
    subplot(1,2,1); plot(real(Xn),imag(Xn),'bo','MarkerFaceColor','b'); grid on; axis equal;
    xlim([-3 3]); ylim([-3 3]); title(sprintf('BEFORE: X_n [%s]',rateName)); xlabel('I'); ylabel('Q');
    subplot(1,2,2); plot(real(Sn),imag(Sn),'ro','MarkerFaceColor','r'); grid on; axis equal;
    xlim([-3 3]); ylim([-3 3]); title(sprintf('AFTER: S_n [%s]',rateName)); xlabel('I'); ylabel('Q');

    %% -------------------------------------------------------------
    %  STAGE 6 : FINAL CSS SIGNAL, FLOATING POINT
    %  -------------------------------------------------------------
    nShowFloat = min(800, length(TxchirpSequences_float));
    tf = 1:nShowFloat;
    fprintf('--- STAGE 6: Final CSS signal, floating point [%s] ---\n', rateName);
    fprintf('  Full signal length : %d samples\n\n', length(TxchirpSequences_float));

    figure('Name',sprintf('STAGE 6 - Final CSS Signal (float) [%s]',rateName),'Color','w','Position',[50 50 1100 750]);
    subplot(3,1,1);
    plot(tf,real(TxchirpSequences_float(tf)),'b-'); hold on;
    plot(tf,imag(TxchirpSequences_float(tf)),'r-'); hold off; grid on;
    legend('I (real)','Q (imag)');
    title(sprintf('STAGE 6a [%s]: CSS signal, time domain',rateName));
    xlabel('Sample index'); ylabel('Amplitude');
    subplot(3,1,2);
    plot(tf,abs(TxchirpSequences_float(tf)),'k-','LineWidth',1.2); grid on;
    title(sprintf('STAGE 6b [%s]: |CSS signal| envelope -- gaps visible',rateName));
    xlabel('Sample index'); ylabel('|Amplitude|');
    subplot(3,1,3);
    instPhase = unwrap(angle(TxchirpSequences_float(tf)));
    instFreqMHz = diff(instPhase)/(2*pi)*samplingFreqMhz;
    plot(instFreqMHz,'m-','LineWidth',1.1); grid on;
    title(sprintf('STAGE 6c [%s]: Instantaneous frequency',rateName));
    xlabel('Sample index'); ylabel('Frequency (MHz, relative)');

    %% -------------------------------------------------------------
    %  STAGE 7 : QUANTIZE FINAL OUTPUT TO Q3.4 -- tx_real ABOVE tx_imag
    %  -------------------------------------------------------------
    TxchirpSequences_q34 = fi(TxchirpSequences_float, T_out, F_out);

    errNum   = sum(abs(TxchirpSequences_float(:) - double(TxchirpSequences_q34(:))).^2);
    errDenom = sum(abs(TxchirpSequences_float(:)).^2);
    thisMSE  = errNum / errDenom;
    mseAll(dataRate+1) = thisMSE;

    fprintf('--- STAGE 7: Final output quantized to Q3.4 [%s] ---\n', rateName);
    fprintf('  Full two-stage MSE : %.8f\n', thisMSE);
    if thisMSE <= 0.005, mseStr='PASSED'; else, mseStr='FAILED'; end
    fprintf('  Requirement (<=0.005) : %s\n\n', mseStr);

    nShow = min(600, length(TxchirpSequences_float));
    tAx = 1:nShow;
    figure('Name',sprintf('STAGE 7 - Float vs Q3.4 output [%s]',rateName),'Color','w','Position',[50 50 1100 800]);
    subplot(2,1,1);
    p3=plot(tAx,real(TxchirpSequences_float(tAx)),'b-','LineWidth',1.3); hold on;
    p4=plot(tAx,real(double(TxchirpSequences_q34(tAx))),'r--','LineWidth',1); hold off; grid on;
    legend([p3 p4],{'Floating point (golden)','Q3.4 quantized output'},'Location','best');
    title(sprintf('STAGE 7a [%s]: tx\\_real, float vs Q3.4 -- MSE=%.6f',rateName,thisMSE));
    xlabel('Sample index'); ylabel('Amplitude');
    subplot(2,1,2);
    p5=plot(tAx,imag(TxchirpSequences_float(tAx)),'b-','LineWidth',1.3); hold on;
    p6=plot(tAx,imag(double(TxchirpSequences_q34(tAx))),'r--','LineWidth',1); hold off; grid on;
    legend([p5 p6],{'Floating point (golden)','Q3.4 quantized output'},'Location','best');
    title(sprintf('STAGE 7b [%s]: tx\\_imag, float vs Q3.4',rateName));
    xlabel('Sample index'); ylabel('Amplitude');

    %% -------------------------------------------------------------
    %  STAGE 8 : EXPORT tx_real / tx_imag TO FILE (Q3.4 binary, WL=8)
    %  -------------------------------------------------------------
    fnameR = sprintf('tx_real_Q3p4_%s.txt', rateTag);
    fnameI = sprintf('tx_imag_Q3p4_%s.txt', rateTag);

    txR = real(TxchirpSequences_q34);
    txI = imag(TxchirpSequences_q34);

    fidR = fopen(fnameR,'wt');
    fprintf(fidR, '// tx_real, Q3.4 fixed point (WL=8, 1 sign+3 int+4 frac), data rate %s\n', rateName);
    for n = 1:length(txR)
        fprintf(fidR, '%s\n', bin(txR(n)));
    end
    fclose(fidR);

    fidI = fopen(fnameI,'wt');
    fprintf(fidI, '// tx_imag, Q3.4 fixed point (WL=8, 1 sign+3 int+4 frac), data rate %s\n', rateName);
    for n = 1:length(txI)
        fprintf(fidI, '%s\n', bin(txI(n)));
    end
    fclose(fidI);

    fprintf('--- STAGE 8: Exported Q3.4 output files [%s] ---\n', rateName);
    fprintf('  %s  (%d entries)\n', fnameR, length(txR));
    fprintf('  %s  (%d entries)\n\n', fnameI, length(txI));

    TxFloatAll{dataRate+1} = TxchirpSequences_float;
    TxOutAll{dataRate+1}   = TxchirpSequences_q34;
end

%% ========================================================================
%  FINAL SIDE-BY-SIDE COMPARISON, BOTH DATA RATES -- tx_real / tx_imag stacked
%  ========================================================================
fprintf('\n#########################################################\n');
fprintf('#  FINAL COMPARISON: ROM=Q1.4, OUTPUT=Q3.4, BOTH DATA RATES\n');
fprintf('#  Stimulus: payload.txt (%d bytes)\n', numPayloadBytes);
fprintf('#########################################################\n\n');

fprintf('%-12s | %-12s | %-14s | %-10s\n', 'Data Rate', 'ROM MSE', 'Output MSE', 'Result');
fprintf('%-12s | %-12s | %-14s | %-10s\n', '---------', '-------', '----------', '------');
for r = 1:2
    if mseAll(r) <= 0.005, rStr='PASS'; else, rStr='FAIL'; end
    fprintf('%-12s | %-12.8f | %-14.8f | %-10s\n', rateLabels{r}, romMSEAll(r), mseAll(r), rStr);
end

figure('Name','FINAL COMPARISON - Both Data Rates','Color','w','Position',[50 50 1100 900]);
n1 = min(800, length(TxFloatAll{1})); n2 = min(800, length(TxFloatAll{2}));

subplot(4,1,1);
q1=plot(1:n1,real(TxFloatAll{1}(1:n1)),'b-','LineWidth',1.2); hold on;
q2=plot(1:n1,real(double(TxOutAll{1}(1:n1))),'r--','LineWidth',1); hold off; grid on;
legend([q1 q2],{'Floating point','Q3.4 output'},'Location','best');
title(sprintf('1 Mb/s -- tx\\_real -- MSE=%.6f',mseAll(1))); xlabel('Sample index'); ylabel('Amplitude');

subplot(4,1,2);
q1b=plot(1:n1,imag(TxFloatAll{1}(1:n1)),'b-','LineWidth',1.2); hold on;
q2b=plot(1:n1,imag(double(TxOutAll{1}(1:n1))),'r--','LineWidth',1); hold off; grid on;
legend([q1b q2b],{'Floating point','Q3.4 output'},'Location','best');
title('1 Mb/s -- tx\_imag'); xlabel('Sample index'); ylabel('Amplitude');

subplot(4,1,3);
q3=plot(1:n2,real(TxFloatAll{2}(1:n2)),'b-','LineWidth',1.2); hold on;
q4=plot(1:n2,real(double(TxOutAll{2}(1:n2))),'r--','LineWidth',1); hold off; grid on;
legend([q3 q4],{'Floating point','Q3.4 output'},'Location','best');
title(sprintf('250 kb/s -- tx\\_real -- MSE=%.6f',mseAll(2))); xlabel('Sample index'); ylabel('Amplitude');

subplot(4,1,4);
q3b=plot(1:n2,imag(TxFloatAll{2}(1:n2)),'b-','LineWidth',1.2); hold on;
q4b=plot(1:n2,imag(double(TxOutAll{2}(1:n2))),'r--','LineWidth',1); hold off; grid on;
legend([q3b q4b],{'Floating point','Q3.4 output'},'Location','best');
title('250 kb/s -- tx\_imag'); xlabel('Sample index'); ylabel('Amplitude');

fprintf('\n=========================================================\n');
fprintf(' FULL DUAL-STAGE MODEL COMPLETE (payload.txt, both rates, all stages).\n');
fprintf(' Preamble+SFD and tx_real/tx_imag exported for both data rates.\n');
fprintf('=========================================================\n');