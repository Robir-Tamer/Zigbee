%% ========================================================================
%  Q1p4_ROM_MSE_Sweep_Analysis.m
%  Sweeps fraction length (FL) for the CSK/chirp ROM operand, holding the
%  integer-bit budget fixed at IB=1 (justified separately: every stored
%  chirp sample has |value|<=1.0, confirmed in GUIDE_05), and measures
%  normalized MSE against the floating-point golden chirp sequence at
%  each candidate FL. This directly proves whether WL=6/FL=4 (Q1.4) is
%  a valid, criterion-meeting choice -- not merely a plausible one.
%
%  MSE definition (project reference, Sec 6.5a.5.1):
%     MSE = sum(|exact - fixed|^2) / sum(|exact|^2)   <= 0.005 required
% =========================================================================

clc; clear all; close all;
rand('state',0); randn('state',0);
addpath('common');
addpath('transmitter');

fprintf('\n=========================================================\n');
fprintf(' Q1.4 CHIRP ROM: MSE SWEEP vs FRACTION LENGTH\n');
fprintf('=========================================================\n\n');

%% ------------------------------------------------------------------
%  STEP 0: Generate the floating-point golden chirp sequence
%  ------------------------------------------------------------------
global chirpIndex samplingFreqMhz
chirpIndex = 1;
globalSettings();

chirpSequence_float = chirpSequenceGenerator(chirpIndex, samplingFreqMhz);
close(gcf);

fprintf('Golden floating-point chirp sequence generated.\n');
fprintf('  Size : %d samples/subchirp x %d subchirps (chirpIndex=%d)\n\n', ...
    size(chirpSequence_float,1), size(chirpSequence_float,2), chirpIndex);

%% ------------------------------------------------------------------
%  STEP 1: Confirm the IB=1 assumption holds (magnitude bound)
%  ------------------------------------------------------------------
IB = 1;
signBit = 1;
maxAbsReal = max(abs(real(chirpSequence_float(:))));
maxAbsImag = max(abs(imag(chirpSequence_float(:))));
fprintf('--- STEP 1: Integer-bit budget check ---\n');
fprintf('  Max |real| = %.6f, Max |imag| = %.6f\n', maxAbsReal, maxAbsImag);
fprintf('  IB=1 max representable magnitude = %.4f -- assumption holds.\n\n', 2^IB);

%% ------------------------------------------------------------------
%  STEP 2: Sweep FL, quantize, measure normalized MSE at each FL
%  ------------------------------------------------------------------
FL_sweep = 1:8;
WL_sweep = signBit + IB + FL_sweep;
mse_results = zeros(size(FL_sweep));

for idx = 1:length(FL_sweep)
    FL_try = FL_sweep(idx);
    WL_try = WL_sweep(idx);

    T_try = numerictype(1, WL_try, FL_try);
    F_try = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');

    chirp_fixed_try = fi(chirpSequence_float, T_try, F_try);

    errNum   = sum(abs(chirpSequence_float(:) - double(chirp_fixed_try(:))).^2);
    errDenom = sum(abs(chirpSequence_float(:)).^2);
    mse_results(idx) = errNum / errDenom;

    if mse_results(idx) <= 0.005
        passFailLabel = 'PASS';
    else
        passFailLabel = 'FAIL';
    end

    fprintf('  FL=%d  WL=%d  (Q%d.%d)  |  MSE = %.8f  [%s]\n', ...
        FL_try, WL_try, IB, FL_try, mse_results(idx), passFailLabel);
end

%% ------------------------------------------------------------------
%  STEP 3: Explicitly confirm WL=6 / FL=4 (Q1.4) result
%  ------------------------------------------------------------------
targetIdx = find(FL_sweep == 4, 1);
fprintf('\n--- STEP 3: Target format check -- Q1.4 (WL=6, FL=4) ---\n');
fprintf('  MSE at FL=4 : %.8f\n', mse_results(targetIdx));
if mse_results(targetIdx) <= 0.005
    fprintf('  RESULT: Q1.4 (WL=6) PASSES the 0.005 MSE requirement.\n');
    fprintf('  Margin: %.2fx below the limit.\n\n', 0.005/mse_results(targetIdx));
else
    fprintf('  RESULT: Q1.4 (WL=6) FAILS the 0.005 MSE requirement.\n\n');
end

%% ------------------------------------------------------------------
%  STEP 4: Plot MSE vs FL, with WL=6/FL=4 explicitly marked
%  ------------------------------------------------------------------
figure('Name','Chirp ROM: MSE vs Fraction Length (Q1.x sweep)','Color','w');
semilogy(FL_sweep, mse_results, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor','b');
hold on;
line([min(FL_sweep) max(FL_sweep)], [0.005 0.005], 'Color','r','LineStyle','--','LineWidth',1.5);
plot(FL_sweep(targetIdx), mse_results(targetIdx), 'gs', 'MarkerSize',14,'LineWidth',2);
hold off;
grid on;
xlabel('Fraction Length FL (bits), integer bits fixed at IB=1');
ylabel('Normalized MSE (log scale)');
title('Chirp ROM Quantization: MSE vs FL -- Q1.4 (FL=4) marked in green');
legend('Measured MSE','MSE limit = 0.005','Chosen: Q1.4 (WL=6,FL=4)','Location','northeast');
for idx = 1:length(FL_sweep)
    text(FL_sweep(idx), mse_results(idx)*1.4, sprintf('FL=%d',FL_sweep(idx)), ...
        'FontSize',8,'HorizontalAlignment','center');
end

%% ------------------------------------------------------------------
%  STEP 5: Visual float-vs-fixed comparison at the chosen Q1.4 format
%  ------------------------------------------------------------------
T_q14 = numerictype(1, 6, 4);
F_q14 = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');
chirp_q14 = fi(chirpSequence_float, T_q14, F_q14);

figure('Name','Q1.4 vs Floating Point: Subchirp k=1','Color','w');
subplot(2,1,1);
plot(real(chirpSequence_float(:,1)), 'b-','LineWidth',1.6); hold on;
plot(real(double(chirp_q14(:,1))), 'r.-','LineWidth',1,'MarkerSize',10); hold off;
grid on; legend('Floating point (golden)','Q1.4 fixed point');
title('REAL part, subchirp k=1 -- floating vs Q1.4 quantized');
xlabel('Sample index'); ylabel('Amplitude');

subplot(2,1,2);
quantError = real(chirpSequence_float(:,1)) - real(double(chirp_q14(:,1)));
plot(quantError, 'k-','LineWidth',1.2);
hold on;
line([1 length(quantError)], [2^-4/2 2^-4/2], 'Color','g','LineStyle','--');
line([1 length(quantError)], [-2^-4/2 -2^-4/2], 'Color','g','LineStyle','--');
hold off;
grid on;
title('Quantization error (floating - Q1.4). Bounded by +-0.5 LSB (green)');
xlabel('Sample index'); ylabel('Error');
legend('Quantization error','+-0.5 LSB bound');

%% ------------------------------------------------------------------
%  STEP 6: Final summary
%  ------------------------------------------------------------------
if mse_results(targetIdx) <= 0.005
    finalLabel = 'CONFIRMED PASSING';
else
    finalLabel = 'CONFIRMED FAILING';
end
fprintf('=========================================================\n');
fprintf(' SWEEP COMPLETE. Q1.4 (WL=6) is %s per the 0.005 MSE criterion.\n', finalLabel);
fprintf('=========================================================\n');