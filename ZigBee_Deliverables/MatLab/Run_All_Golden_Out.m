%% ========================================================================
%  Run_All_Golden_Out.m
%  Runs every golden-output generation script in pipeline order.
%
%  Each stage script begins with "clc; clear all; close all", which would
%  wipe this runner's own workspace if the scripts were executed directly.
%  Each one is therefore launched through runOneScript(), a local function
%  whose workspace is separate -- the clear only affects that scope.
%
%  Usage:  place this file in the same folder as the stage scripts
%          (the folder containing payload.txt, common/, transmitter/)
%          then simply run it.
% =========================================================================

clc; close all;

%% ---- Scripts to run, in order -------------------------------------
scriptList = { ...
    'Gold_Out_till_01_ZeroPadding', ...
    'Gold_Out_till_02_Demux', ...
    'Gold_Out_till_03_SymbolMapper', ...
    'Gold_Out_till_04_interleaver', ...
    'Gold_Out_till_06_QPSK', ...
    'Gold_Out_till_07_DQPSK', ...
    'Gold_Out_Fixed_Point_Model' };

%% ---- Make sure the output folders exist ---------------------------
outDirs = {'./Golden_out', './Golden_out/1Mbps', './Golden_out/250Kbps'};
for k = 1:numel(outDirs)
    if ~exist(outDirs{k}, 'dir')
        mkdir(outDirs{k});
        fprintf('Created folder : %s\n', outDirs{k});
    end
end

%% ---- Run them ------------------------------------------------------
nScripts = numel(scriptList);
status   = cell(nScripts, 1);
elapsed  = zeros(nScripts, 1);

fprintf('\n#########################################################\n');
fprintf(' RUNNING %d GOLDEN-OUTPUT SCRIPTS\n', nScripts);
fprintf('#########################################################\n');

for k = 1:nScripts

    name = scriptList{k};

    fprintf('\n---------------------------------------------------------\n');
    fprintf(' [%d/%d] %s\n', k, nScripts, name);
    fprintf('---------------------------------------------------------\n');

    if isempty(which(name))
        status{k}  = 'NOT FOUND';
        elapsed(k) = 0;
        fprintf('  *** SKIPPED: %s.m is not on the MATLAB path.\n', name);
        continue;
    end

    t0 = tic;
    try
        runOneScript(name);
        elapsed(k) = toc(t0);
        status{k}  = 'OK';
    catch ME
        elapsed(k) = toc(t0);
        status{k}  = 'FAILED';
        fprintf(2, '  *** ERROR in %s: %s\n', name, ME.message);
        if ~isempty(ME.stack)
            fprintf(2, '      at %s (line %d)\n', ...
                ME.stack(1).name, ME.stack(1).line);
        end
        % To abort the whole run on the first failure, uncomment:
        % rethrow(ME);
    end

    close all;
end

%% ---- Summary -------------------------------------------------------
fprintf('\n#########################################################\n');
fprintf(' SUMMARY\n');
fprintf('#########################################################\n');
for k = 1:nScripts
    fprintf('  %-35s %-10s %6.2f s\n', scriptList{k}, status{k}, elapsed(k));
end
nOK = sum(strcmp(status, 'OK'));
fprintf('---------------------------------------------------------\n');
fprintf('  %d/%d succeeded, total %.2f s\n', nOK, nScripts, sum(elapsed));
fprintf('#########################################################\n');


%% ========================================================================
%  Local function -- isolates each script's "clear all" from this runner
% =========================================================================
function runOneScript(scriptName)
    evalin('base', '');      % no-op, keeps base workspace untouched
    run(scriptName);         % executes inside THIS function's workspace
end
