% =========================================================================
% Analog IC Design Master Script using gm/ID Methodology
% General For any Technology
% Author: Hassan Shehata
% Institution: Mansoura University
% Date: March 2026
%
% Acknowledgment: This script utilizes the 'lookup' functions developed 
% by Prof. Boris Murmann (Stanford University) for data interpolation.
% =========================================================================

function c = techsweep_config_generic
% GENERIC TECHNOLOGY CONFIGURATION FILE
% Use this template to adapt any PDK (TSMC, UMC, GPDK, etc.)

%% 1. Path & Model Definitions
c.modelfile = 'Your/model/path.scs'; % Full path to .scs file
c.modelinfo = 'PDK_node';             % Just a label for the plots
c.corner    = 'tt';                          % Typical corner name (e.g., tt, lib, nom)
c.temp      = 300;                           % Temperature in Kelvin

% Model Names (Find these using grep in the .scs file)
c.modeln    = 'NMOS'; 
c.modelp    = 'PMOS';

% Output Database Names
c.savefilen = 'tech_nch';
c.savefilep = 'tech_pch';

% Simulator Command (2>&1 redirects errors to techsweep.out for debugging)
c.simcmd = 'spectre techsweep.scs > techsweep.out 2>&1';
c.outfile = 'techsweep.raw';
c.sweep   = 'sweepvds_sweepvgs-sweep';

%% 2. Sweep Parameters (Adjust based on Technology limits)
c.VGS_step = 25e-3; c.VGS_max = 1.0; 
c.VDS_step = 25e-3; c.VDS_max = 1.0;
c.VSB_step = 0.1;   c.VSB_max = 1.0;

c.VGS = 0:c.VGS_step:c.VGS_max;
c.VDS = 0:c.VDS_step:c.VDS_max;
c.VSB = 0:c.VSB_step:c.VSB_max;

% Channel Length array (Adjust based on PDK Minimum L)
c.LENGTH = [0.09, 0.5, 1]; 
c.WIDTH  = 10; % Fixed width for characterization
c.NFING  = 5;  % Number of fingers

%% 3. Variable Mapping (TO BE UPDATED AFTER RUNNING PDK_PROBE)
% --- Copy & Paste this code into techsweep_config_generic.m ---

% Variable mapping
c.outvars = {'ID','VT','IGD','IGS','GM','GMB','GDS','CGG','CGS','CSG','CGD','CDG','CGB','CDD','CSS','VDSAT','VEARLY'};

% MN Mapping
c.n{1} = {'mn:ids', 'A', [1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.n{2} = {'mn:vth', 'V', [0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.n{3} = {'mn:igd', 'A', [0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.n{4} = {'mn:igs', 'A', [0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.n{5} = {'mn:gm', 'S', [0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0]};
c.n{6} = {'mn:gmbs', 'S', [0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0]};
c.n{7} = {'mn:gds', 'S', [0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0]};
c.n{8} = {'mn:cgg', 'F', [0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0]};
c.n{9} = {'mn:cgs', 'F', [0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0]};
c.n{10} = {'mn:csg', 'F', [0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0]};
c.n{11} = {'mn:cgd', 'F', [0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0]};
c.n{12} = {'mn:cdg', 'F', [0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0]};
c.n{13} = {'mn:cgb', 'F', [0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0]};
c.n{14} = {'mn:cdd', 'F', [0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0]};
c.n{15} = {'mn:css', 'F', [0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0]};
c.n{16} = {'mn:vdsat', 'V', [0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0]};
c.n{17} = {'mn:vearly', 'V', [0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1]};

% MP Mapping
c.p{1} = {'mp:ids', 'A', [1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.p{2} = {'mp:vth', 'V', [0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.p{3} = {'mp:igd', 'A', [0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.p{4} = {'mp:igs', 'A', [0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0]};
c.p{5} = {'mp:gm', 'S', [0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0]};
c.p{6} = {'mp:gmbs', 'S', [0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0]};
c.p{7} = {'mp:gds', 'S', [0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0]};
c.p{8} = {'mp:cgg', 'F', [0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0]};
c.p{9} = {'mp:cgs', 'F', [0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0]};
c.p{10} = {'mp:csg', 'F', [0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0]};
c.p{11} = {'mp:cgd', 'F', [0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0]};
c.p{12} = {'mp:cdg', 'F', [0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0]};
c.p{13} = {'mp:cgb', 'F', [0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0]};
c.p{14} = {'mp:cdd', 'F', [0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0]};
c.p{15} = {'mp:css', 'F', [0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0]};
c.p{16} = {'mp:vdsat', 'V', [0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0]};
c.p{17} = {'mp:vearly', 'V', [0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1]};

%% 4. Netlist Generation (The Heart of the Script)
netlist = sprintf([...
'// Automatically generated techsweep netlist \n'...
'include "%s" section=%s \n'... % Includes the PDK models
'include "techsweep_params.scs" \n'...
'save mn:oppoint mp:oppoint \n'... % Save DC parameters for BOTH
'parameters gs=0 ds=0 \n'...
'// --- NMOS Instantiation --- \n'...
'vdsn (vdn 0) vsource dc=ds \n'...
'vgsn (vgn 0) vsource dc=gs \n'...
'vbsn (vbn 0) vsource dc=-sb \n'...
'mn (vdn vgn 0 vbn) %s l=length*1u w=%g*1u m=%g \n'... 
'// --- PMOS Instantiation --- \n'...
'vdsp (vdp 0) vsource dc=-ds \n'...
'vgsp (vgp 0) vsource dc=-gs \n'...
'vbsp (vbp 0) vsource dc=sb \n'...
'mp (vdp vgp 0 vbp) %s l=length*1u w=%g*1u m=%g \n'... 
'options1 options rawfmt=psfbin rawfile="./techsweep.raw" redefinedparams=ignore \n'...
'sweepvds sweep param=ds start=0 stop=%g step=%g { \n'...
'  sweepvgs dc param=gs start=0 stop=%g step=%g \n'...
'}\n'...
], c.modelfile, c.corner, ...
   c.modeln, c.WIDTH, c.NFING, ... % NMOS Parameters
   c.modelp, c.WIDTH, c.NFING, ... % PMOS Parameters
   c.VDS_max, c.VDS_step, c.VGS_max, c.VGS_step);

fid = fopen('techsweep.scs', 'w'); fprintf(fid, netlist); fclose(fid);
return
