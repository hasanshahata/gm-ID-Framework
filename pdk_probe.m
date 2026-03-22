% =========================================================================
% SCRIPT: pdk_probe_auto.m (V4 - Direct Query Method)
% Purpose: Bypasses MATLAB struct shadowing by directly probing specific 
%          signals from the Cadence database. 100% Bulletproof.
% =========================================================================
clc; disp('Directly Probing Cadence Database for 17 Variables...');

rawfile = 'techsweep.raw';
dataset = 'sweepvds_sweepvgs-sweep';

try
    % Array of 17 variables required by the framework
    outvars = {'ID','VT','IGD','IGS','GM','GMB','GDS','CGG','CGS','CSG','CGD','CDG','CGB','CDD','CSS','VDSAT','VEARLY'};
    
    % Expected Cadence suffixes and their physical units
    search_map = {
        'ids', 'A'; 'vth', 'V'; 'igd', 'A'; 'igs', 'A'; 'gm', 'S';
        'gmbs', 'S'; 'gds', 'S'; 'cgg', 'F'; 'cgs', 'F'; 'csg', 'F';
        'cgd', 'F'; 'cdg', 'F'; 'cgb', 'F'; 'cdd', 'F'; 'css', 'F';
        'vdsat', 'V'; 'vearly', 'V'
    };

    prefixes = {'n', 'mn'; 'p', 'mp'};
    
    fprintf('\n%% --- Copy & Paste this code into techsweep_config_generic.m ---\n\n');
    
    % --- NEW: Print the c.outvars line dynamically ---
    outvars_str = strjoin(outvars, ''',''');
    fprintf('c.outvars = {''%s''};\n\n', outvars_str);
    % -------------------------------------------------
    
    % Loop over NMOS (mn) and PMOS (mp)
    for t = 1:2
        m_type = prefixes{t,1};
        m_prefix = prefixes{t,2};
        fprintf('%% %s Mapping\n', upper(m_prefix));
        
        for i = 1:length(outvars)
            cand_name = [m_prefix ':' search_map{i,1}];
            unit = search_map{i,2};
            
            % Special Check: Some PDKs use 'gmb' instead of 'gmbs'
            if strcmp(outvars{i}, 'GMB')
                try
                    cds_srr(rawfile, dataset, cand_name); % Try gmbs
                catch
                    cand_name = [m_prefix ':gmb'];        % Fallback to gmb
                end
            end
            
            % DIRECT PROBE: Ask Cadence specifically for this signal
            try
                % If the signal exists, cds_srr will not throw an error
                dummy_read = cds_srr(rawfile, dataset, cand_name);
                
                % Generate the binary vector [0 0 1 0 0 ...]
                vec = zeros(1, length(outvars)); 
                vec(i) = 1;
                vec_str = num2str(vec);
                
                % Print the exact MATLAB code needed
                fprintf('c.%s{%d} = {''%s'', ''%s'', [%s]};\n', ...
                        m_type, i, cand_name, unit, vec_str);
            catch
                % If it fails, print a warning as a comment
                fprintf('%% Warning: Signal ''%s'' was not found in the database.\n', cand_name);
            end
        end
        fprintf('\n');
    end
    disp('Auto-Mapping generation complete. You can copy the code above.');
    
catch
    disp('Error: Could not access techsweep.raw. Did the simulation complete?');
end