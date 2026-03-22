% =========================================================================
% STEP 1: LINKING MATLAB TO CADENCE SPECTRE TOOLBOX
% =========================================================================
% This script adds the Cadence results reader (cds_srr) to MATLAB's path.
% Change the path below to match your server's installation directory.

cadence_path = 'put/your/path';
addpath(cadence_path);

% Check if the link is successful
if exist('cds_srr', 'file')
    disp('Cadence Toolbox linked successfully!');
    help cds_srr % Displays documentation
else
    error('Path not found. Check your Cadence installation directory.');
end
