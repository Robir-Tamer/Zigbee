%% ========================================================================
%  Q3p4_Output_Justification.m
%  Q3.4 (8-bit) output format justification for tx_real/tx_imag.
%  Format derived from multiplier operands: DQPSK (Q1.0) x Chirp ROM (Q1.4).
%  Verified against real payload.txt stimulus, full-chain floating-point
%  reference, per spec MSE criterion (Sec 6.5a.5.1, MSE <= 0.005).
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);
addpath('common');
addpath('transmitter');

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

global chirpIndex samplingFreqMhz
chirpIndex = 1;
globalSettings();
dataRate = 0;

chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
close(gcf);

TxchirpSequences_float = ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_float);

T_q34 = numerictype(1, 8, 4);
F_q34 = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');
TxchirpSequences_q34 = fi(TxchirpSequences_float, T_q34, F_q34);

errNum   = sum(abs(TxchirpSequences_float(:) - double(TxchirpSequences_q34(:))).^2);
errDenom = sum(abs(TxchirpSequences_float(:)).^2);
mseQ34   = errNum / errDenom;
marginX  = 0.005 / mseQ34;

if mseQ34 <= 0.005
    verdict = 'PASS';
else
    verdict = 'FAIL';
end

fprintf('=========================================================\n');
fprintf(' Q3.4 OUTPUT FORMAT VERIFICATION -- tx_real / tx_imag\n');
fprintf('=========================================================\n');
fprintf(' Format           : Q3.4, WL=8 (1 sign + 3 int + 4 frac)\n');
fprintf(' Derived from     : DQPSK Q1.0 x Chirp ROM Q1.4\n');
fprintf(' Stimulus         : payload.txt (%d bytes, %d samples)\n', numPayloadBytes, length(TxchirpSequences_float));
fprintf(' Normalized MSE   : %.8f\n', mseQ34);
fprintf(' Spec limit       : 0.005\n');
fprintf(' Margin           : %.2fx below limit\n', marginX);
fprintf(' Verdict          : %s\n', verdict);
fprintf('=========================================================\n');

%% ------------------------------------------------------------------
%  Vibrant color palette
%  ------------------------------------------------------------------
colFloat  = [0.0000 0.4470 0.9410];
colFixed  = [0.9500 0.1250 0.1250];
colErrR   = [0.1000 0.7500 0.3000];
colErrI   = [0.7500 0.1000 0.8500];
colBound  = [1.0000 0.6000 0.0000];
colBar    = [0.1000 0.5500 0.9500];

nShow = min(800, length(TxchirpSequences_float));
tAxis = 1:nShow;

% Bigger figure, no sgtitle (older-MATLAB compatible) -- use a manual
% annotation textbox instead, but positioned ABOVE the top subplot's own
% title with explicit margin (fixes the earlier overlap).
figure('Name','Q3.4 Output Verification','Color','w', 'Position',[50 50 1300 1000]);

subplot(3,1,1);
p1 = plot(tAxis, real(TxchirpSequences_float(tAxis)), 'Color',colFloat, 'LineWidth',1.8); hold on;
p2 = plot(tAxis, real(double(TxchirpSequences_q34(tAxis))), '--', 'Color',colFixed, 'LineWidth',1.4); hold off;
grid on; box on;
legend([p1 p2], {'Floating-point reference','Q3.4 quantized output'}, ...
    'Location','southoutside', 'Orientation','horizontal', 'FontSize',9);
title(sprintf('tx\\_real -- MSE = %.2e   |   Limit = 5.00e-03   |   %s', mseQ34, verdict), ...
    'FontSize',12, 'FontWeight','bold');
xlabel('Sample Index'); ylabel('Amplitude');
set(gca,'FontSize',10);

subplot(3,1,2);
p3 = plot(tAxis, imag(TxchirpSequences_float(tAxis)), 'Color',colFloat, 'LineWidth',1.8); hold on;
p4 = plot(tAxis, imag(double(TxchirpSequences_q34(tAxis))), '--', 'Color',colFixed, 'LineWidth',1.4); hold off;
grid on; box on;
legend([p3 p4], {'Floating-point reference','Q3.4 quantized output'}, ...
    'Location','southoutside', 'Orientation','horizontal', 'FontSize',9);
title('tx\_imag -- Floating-Point Reference vs. Q3.4 Fixed-Point Output', ...
    'FontSize',12, 'FontWeight','bold');
xlabel('Sample Index'); ylabel('Amplitude');
set(gca,'FontSize',10);

subplot(3,1,3);
quantErrorReal = abs(real(TxchirpSequences_float(tAxis)) - real(double(TxchirpSequences_q34(tAxis))));
quantErrorImag = abs(imag(TxchirpSequences_float(tAxis)) - imag(double(TxchirpSequences_q34(tAxis))));
h1 = plot(tAxis, quantErrorReal, 'Color',colErrR, 'LineWidth',1.3); hold on;
h2 = plot(tAxis, quantErrorImag, 'Color',colErrI, 'LineWidth',1.3);
h3 = line([1 nShow], [2^-4/2 2^-4/2], 'Color',colBound,'LineStyle',':','LineWidth',1.8);
line([1 nShow], [0 0], 'Color',[0.6 0.6 0.6], 'LineStyle','-','LineWidth',0.5, 'HandleVisibility','off');
hold off;
grid on; box on;
legend([h1 h2 h3], {'|Error| tx\_real','|Error| tx\_imag','\pm0.5 LSB bound (Q3.4)'}, ...
    'Location','northeastoutside', 'FontSize',9);
title('Absolute Quantization Error per Sample', 'FontSize',12, 'FontWeight','bold');
xlabel('Sample Index'); ylabel('|Error| (linear amplitude)');
set(gca,'FontSize',10);

% Reclaim vertical space: shrink subplot heights slightly and shift them
% down, leaving a clean margin at the top for the annotation banner so
% it can NEVER overlap subplot 1's title.
subplot(3,1,1); pos1 = get(gca,'Position'); set(gca,'Position',[pos1(1) pos1(2)-0.03 pos1(3) pos1(4)]);
subplot(3,1,2); pos2 = get(gca,'Position'); set(gca,'Position',[pos2(1) pos2(2)-0.015 pos2(3) pos2(4)]);

annotation('textbox',[0.05 0.965 0.9 0.03], 'String', ...
    sprintf('CSS Transmitter Output Verification: Q3.4 Fixed-Point Format vs. Floating-Point Reference (%s)', verdict), ...
    'EdgeColor','none','HorizontalAlignment','center','FontWeight','bold','FontSize',15);

figure('Name','Q3.4 MSE Compliance','Color','w','Position',[150 150 650 550]);
bar(1, mseQ34, 0.4, 'FaceColor',colBar);
set(gca, 'XTick', 1, 'XTickLabel', {'Q3.4 Measured MSE'}, 'FontSize',11);
xlim([0.3 1.7]);
hold on;
line([0.3 1.7], [0.005 0.005], 'Color',colFixed, 'LineStyle','--', 'LineWidth',2.0);
text(1.35, 0.005, 'Spec Limit (0.005)', 'Color',colFixed, 'FontSize',11, 'VerticalAlignment','bottom');
hold off;
set(gca,'YScale','log');
grid on; box on;
ylabel('Normalized MSE (log scale)', 'FontSize',11);
title({'Q3.4 Output Format: MSE Compliance Check', ...
       sprintf('Payload: %d bytes   |   Margin: %.1fx below spec limit   |   Verdict: %s', ...
       numPayloadBytes, marginX, verdict)}, 'FontSize',12, 'FontWeight','bold');