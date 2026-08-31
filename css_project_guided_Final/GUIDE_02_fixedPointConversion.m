%% ========================================================================
%  GUIDE 02 : FLOATING-POINT  ->  FIXED-POINT CONVERSION, EXPLAINED
%  =========================================================================
%
%  THE CORE IDEA (read this before anything else)
%  ------------------------------------------------
%  Floating-point MATLAB numbers (double) have ~15-16 decimal digits of
%  precision and a huge dynamic range. Real hardware doesn't have that: a
%  multiplier, adder, or register in an FPGA/ASIC has a FIXED number of
%  bits. Fixed-point arithmetic is how you MODEL that hardware constraint
%  inside MATLAB, using the "fi" (fixed-point) object type.
%
%  A fixed-point number is described by:
%     - Signed or unsigned          (1 = signed, 0 = unsigned)
%     - Word Length  (WL)           total number of bits
%     - Fraction Length (FL)        how many of those bits are AFTER the
%                                    binary point
%     -> Integer bits = WL - FL - (1 if signed)
%
%  Example: numerictype(1, 12, 9)  means:
%     WL = 12 total bits, FL = 9 fraction bits, 1 sign bit
%     -> integer bits = 12 - 9 - 1 = 2
%     -> range        = -(2^(WL-FL-1)) to +(2^(WL-FL-1) - 2^-FL)
%                      = -2  to  +1.998...
%     -> resolution (1 LSB step) = 2^-FL = 2^-9 = 0.001953125
%
%  WHY WL=12, FL=9 FOR THIS PROJECT?
%  ------------------------------------
%  Your CSS signal (chirp * raised-cosine window * unit-magnitude DQPSK
%  symbol) has a THEORETICAL magnitude ceiling of ~1.0 (unit circle).
%  So you need:
%     - enough INTEGER bits to comfortably represent values up to ~1
%       (1 sign bit + 2 integer bits gives headroom up to ~2.0, which
%        covers small overshoots from summation/rounding)
%     - enough FRACTION bits so that the quantization step (2^-FL) is
%       small enough that the resulting mean-squared error, when compared
%       sample-by-sample against the floating point reference, stays
%       under your target of 0.005.
%
%  This file does NOT just assert "12 bits, 9 fraction bits is correct".
%  It SHOWS you, by sweeping FL from small to large and plotting MSE vs FL,
%  exactly why FL=9 is the right choice and what happens if you pick fewer
%  or more bits. This is the fixed-point equivalent of a bit-width
%  exploration / sensitivity analysis you'd do before locking an RTL
%  datapath width.
%
%  WHERE DO YOU MAKE THIS DECISION IN A HARDWARE FLOW?
%  ------------------------------------------------------
%  Exactly like you are doing here: BEFORE writing RTL, you run a
%  bit-true fixed-point MODEL in MATLAB/Simulink, sweep word lengths,
%  and pick the minimum width that meets your error budget. Then that
%  chosen (WL, FL) becomes your RTL port widths and internal register
%  widths. You do NOT go back and re-derive it after the fact from the
%  hardware; the MATLAB fixed-point model IS the spec for your RTL
%  bit widths.
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' GUIDE 02 : FIXED-POINT CONVERSION AND MSE BUDGETING\n');
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0 : Reproduce the exact same floating point stimulus as GUIDE_01
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz carrierFreqGHz Tchirp Tsub
chirpIndex = 1;
globalSettings();

% For this file we work directly with the CSK generator's chirp sequence,
% because it is the cleanest, most controllable signal to demonstrate
% quantization on (same technique extends directly to the full
% TxchirpSequences signal - see STEP 5 below).
chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
close(gcf); % close the auto-generated instantaneous-frequency plot from
            % chirpSequenceGenerator.m so it doesn't clutter this guide

%% ------------------------------------------------------------------
%  STEP 1 : WHAT DOES "QUANTIZING" ACTUALLY MEAN? (single-value demo)
%  ------------------------------------------------------------------
%  Before quantizing a whole array, look at ONE number so the concept is
%  crystal clear.
% ---------------------------------------------------------------------
exampleValue = 0.633421789;   % an arbitrary floating point value

T_demo = numerictype(1, 12, 9);      % WL=12, FL=9  (our target format)
F_demo = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');
fi_demo = fi(exampleValue, T_demo, F_demo);

fprintf('--- Single value quantization demo ---\n');
fprintf('  Original (floating) value : %.9f\n', exampleValue);
fprintf('  Quantized (fixed) value   : %.9f\n', double(fi_demo));
fprintf('  Quantization ERROR        : %.9f\n', exampleValue - double(fi_demo));
fprintf('  Binary representation     : %s  (12 bits, Q2.9 format)\n', bin(fi_demo));
fprintf('  1 LSB step size (2^-FL)   : %.9f\n\n', 2^-9);

%% ------------------------------------------------------------------
%  STEP 2 : SWEEP FRACTION LENGTH (FL) AND MEASURE MSE
%  ------------------------------------------------------------------
%  This is the exploration that JUSTIFIES choosing FL=9. We hold Word
%  Length constant relationships (WL = FL + 3, keeping 2 integer bits + 1
%  sign bit fixed) and increase FL, watching MSE drop.
% ---------------------------------------------------------------------

FL_sweep = 3:12;                 % try fraction lengths from 3 to 12 bits
mseVsFL  = zeros(size(FL_sweep));

for idx = 1:length(FL_sweep)
    FL_try = FL_sweep(idx);
    WL_try = FL_try + 3;          % keep 1 sign + 2 integer bits always
    T_try  = numerictype(1, WL_try, FL_try);
    F_try  = fimath('RoundingMethod','Nearest','OverflowAction','Saturate',...
                     'ProductMode','SpecifyPrecision','ProductWordLength',WL_try,...
                     'ProductFractionLength',FL_try,'SumMode','SpecifyPrecision',...
                     'SumWordLength',WL_try+2,'SumFractionLength',FL_try);

    chirp_fixed_try = fi(chirpSequence_float, T_try, F_try);
    err = abs(chirpSequence_float - double(chirp_fixed_try)).^2;
    mseVsFL(idx) = mean(err(:));
end

figure('Name','STEP 2 - MSE vs Fraction Length sweep','Color','w');
semilogy(FL_sweep, mseVsFL, 'bo-','LineWidth',1.5,'MarkerFaceColor','b');
hold on;
line([min(FL_sweep) max(FL_sweep)], [0.005 0.005], 'Color','r','LineStyle','--','LineWidth',1.5);
hold off;
grid on;
xlabel('Fraction Length FL (bits)');
ylabel('Measured MSE (log scale)');
title('MSE vs Fraction Length — this is HOW you justify picking FL=9');
legend('Measured MSE at each FL', 'Target MSE = 0.005 (spec limit)', 'Location','northeast');
for idx = 1:length(FL_sweep)
    text(FL_sweep(idx), mseVsFL(idx)*1.3, sprintf('FL=%d',FL_sweep(idx)), ...
        'FontSize',8,'HorizontalAlignment','center');
end

fprintf('--- MSE sweep results ---\n');
for idx = 1:length(FL_sweep)
    if mseVsFL(idx) <= 0.005
        passFail = 'PASS';
    else
        passFail = 'FAIL';
    end
    fprintf('  FL=%2d (WL=%2d) : MSE = %.8f   [%s]\n', ...
        FL_sweep(idx), FL_sweep(idx)+3, mseVsFL(idx), passFail);
end
minPassingFL = FL_sweep(find(mseVsFL <= 0.005, 1, 'first'));
fprintf('\n  => Minimum FL that meets MSE <= 0.005 is FL = %d\n', minPassingFL);
fprintf('  => We choose FL = 9 in this project: comfortable margin below\n');
fprintf('     spec limit, while keeping word length small for hardware cost.\n\n');

%% ------------------------------------------------------------------
%  STEP 3 : LOCK IN THE CHOSEN FIXED-POINT FORMAT (WL=12, FL=9)
%  ------------------------------------------------------------------
%  This numerictype + fimath pair is now your "hardware datapath spec".
%  Every multiply/add downstream should use THESE settings consistently.
% ---------------------------------------------------------------------

WL = 12;
FL = 9;
T_sig = numerictype(1, WL, FL);
F_math = fimath(...
    'RoundingMethod', 'Nearest', ...     % round-to-nearest (vs simple truncation/floor)
    'OverflowAction', 'Saturate', ...    % clip at max/min instead of wrapping (safer for signals)
    'ProductMode', 'SpecifyPrecision', ...
    'ProductWordLength', WL, ...
    'ProductFractionLength', FL, ...
    'SumMode', 'SpecifyPrecision', ...
    'SumWordLength', WL + 2, ...         % extra 2 integer-bit headroom for sums (avoid overflow when adding)
    'SumFractionLength', FL);

chirpSequence_fixed = fi(chirpSequence_float, T_sig, F_math);
errMat = abs(chirpSequence_float - double(chirpSequence_fixed)).^2;
finalMSE = mean(errMat(:));

fprintf('--- Locked-in fixed-point format ---\n');
fprintf('  numerictype(1, %d, %d)  -- signed, %d total bits, %d fraction bits\n', WL, FL, WL, FL);
fprintf('  Resulting MSE           : %.8f\n', finalMSE);
if finalMSE<=0.005
    finalMSEStr = 'PASSED';
else
    finalMSEStr = 'FAILED';
end
fprintf('  Requirement (<=0.005)   : %s\n\n', finalMSEStr);

%% ------------------------------------------------------------------
%  STEP 4 : VISUALIZE FLOATING vs FIXED, AND THE ERROR ITSELF
%  ------------------------------------------------------------------
%  Three-panel view: (a) both signals overlaid, (b) the quantization
%  "staircase" effect zoomed in, (c) the error signal and its histogram.
% ---------------------------------------------------------------------

plotCol = 1;   % which of the 4 subchirp columns to zoom into for clarity
zoomSamples = 1:Tsub;   % one full subchirp length

figure('Name','STEP 4 - Floating vs Fixed-point (single subchirp)','Color','w');

subplot(3,1,1);
plot(zoomSamples, real(chirpSequence_float(zoomSamples,plotCol)), 'b-','LineWidth',1.6); hold on;
plot(zoomSamples, real(double(chirpSequence_fixed(zoomSamples,plotCol))), 'r.-','LineWidth',1,'MarkerSize',10); hold off;
grid on; legend('Floating point (reference)','Fixed point (quantized)');
title('STEP 4a: Real part — floating vs fixed, subchirp k=1');
xlabel('Sample index'); ylabel('Amplitude');

subplot(3,1,2);
% zoom WAY in on just a few samples to see the quantization "staircase"
zoomTight = 1:8;
stairs(zoomTight, real(chirpSequence_float(zoomTight,plotCol)), 'b-','LineWidth',2); hold on;
stairs(zoomTight, real(double(chirpSequence_fixed(zoomTight,plotCol))), 'r-','LineWidth',2); hold off;
grid on; legend('Floating (continuous-like)','Fixed (quantized steps)');
title('STEP 4b: EXTREME zoom (8 samples) — you can see the fixed-point staircase steps here');
xlabel('Sample index'); ylabel('Amplitude');

subplot(3,1,3);
quantError = real(chirpSequence_float(:,plotCol)) - real(double(chirpSequence_fixed(:,plotCol)));
plot(quantError, 'k-','LineWidth',1.2);
hold on;
line([1 length(quantError)], [2^-FL/2 2^-FL/2], 'Color','g','LineStyle','--');
line([1 length(quantError)], [-2^-FL/2 -2^-FL/2], 'Color','g','LineStyle','--');
hold off;
grid on;
title('STEP 4c: Quantization ERROR (floating - fixed). Should stay within +-0.5 LSB (green lines)');
xlabel('Sample index'); ylabel('Error');
legend('Quantization error', '+-0.5 LSB bound');

%% ------------------------------------------------------------------
%  STEP 5 : APPLY THE SAME CONVERSION TO THE FULL TRANSMITTER OUTPUT
%  ------------------------------------------------------------------
%  Now scale up: run the ENTIRE transmitter chain in floating point, THEN
%  quantize the final CSS output signal the same way, and measure MSE on
%  the full burst (not just the raw chirp table). This is your true
%  end-to-end fixed-point compliance check.
% ---------------------------------------------------------------------

globalSettings(); % re-run to also populate codeword tables etc, needed by Tx chain
payloadBytes = 4;
incomingStream = randi([0 1], 1, payloadBytes*8);
dataRate = 0;

chirpSequence_for_tx = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
close(gcf);

TxchirpSequences_float = ChirpSpreadSpectrum_Tx(incomingStream, dataRate, chirpSequence_for_tx);

% Quantize the full CSS output the SAME way (same T_sig/F_math as locked
% in above at Step 3 -- consistency is what matters)
TxchirpSequences_fixed = fi(TxchirpSequences_float, T_sig, F_math);

errVecFull = abs(TxchirpSequences_float - double(TxchirpSequences_fixed)).^2;
fullChainMSE = mean(errVecFull(:));

fprintf('--- Full transmitter chain fixed-point compliance ---\n');
fprintf('  Full CSS signal length  : %d samples\n', length(TxchirpSequences_float));
fprintf('  Full-chain MSE          : %.8f\n', fullChainMSE);
if fullChainMSE<=0.005
    fullChainStr = 'PASSED';
else
    fullChainStr = 'FAILED';
end
fprintf('  Requirement (<=0.005)   : %s\n\n', fullChainStr);

nShow = min(600, length(TxchirpSequences_float));
tAxis = 1:nShow;

figure('Name','STEP 5 - FULL CHAIN: Floating vs Fixed CSS output','Color','w');
subplot(2,1,1);
plot(tAxis, real(TxchirpSequences_float(tAxis)), 'b-','LineWidth',1.3); hold on;
plot(tAxis, real(double(TxchirpSequences_fixed(tAxis))), 'r--','LineWidth',1); hold off;
grid on; legend('Floating point (golden reference)','Fixed point (12-bit, 9-frac)');
title(sprintf('STEP 5a: Final CSS signal, REAL part — full chain MSE = %.6f', fullChainMSE));
xlabel('Sample index'); ylabel('Amplitude');

subplot(2,1,2);
diffSignal = abs(real(TxchirpSequences_float(tAxis)) - real(double(TxchirpSequences_fixed(tAxis))));
plot(tAxis, diffSignal, 'k-');
grid on;
title('STEP 5b: |Error| between floating and fixed, sample by sample');
xlabel('Sample index'); ylabel('|Error|');

fprintf('=========================================================\n');
fprintf(' FIXED-POINT GUIDE COMPLETE.\n');
fprintf(' Key takeaway: fixed-point conversion is NOT a different\n');
fprintf(' algorithm. It is the SAME floating-point signal flow, with\n');
fprintf(' fi() quantization applied at the points a real ADC/DAC or\n');
fprintf(' arithmetic unit would sit in hardware. You tune (WL,FL) by\n');
fprintf(' sweeping and checking MSE against the floating-point golden\n');
fprintf(' reference, exactly as done in Step 2 above.\n');
fprintf('=========================================================\n');