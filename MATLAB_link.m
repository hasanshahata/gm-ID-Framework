% =========================================================================
% STEP 1: LINKING MATLAB TO CADENCE SPECTRE TOOLBOX
% =========================================================================
% Analog IC Design Master Script using gm/ID Methodology
% General For any Technology
% Author: Hassan Shehata
% Institution: Mansoura University
% Date: March 2026
% =========================================================================

% Add both the main matlab folder and the 64bit subfolder
cadence_path_main = '/usr/local/cadence/MMSIM141/tools.lnx86/spectre/matlab';
cadence_path_64 = fullfile(cadence_path_main, '64bit');

addpath(cadence_path_main);
addpath(cadence_path_64);

% Check for the REAL engine (cds_innersrr) not just the wrapper (cds_srr)
if exist('cds_innersrr', 'file') == 3 % 3 means it's a compiled MEX file
    disp('Cadence Toolbox (including 64-bit MEX files) linked successfully!');
else
    disp('Warning: cds_srr found, but cds_innersrr (MEX file) is missing!');
    error('Please verify that the "64bit" folder exists in your Cadence MATLAB directory.');
end
