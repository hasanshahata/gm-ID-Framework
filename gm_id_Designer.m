% =========================================================================
% Analog IC Design Master Script -- gm/ID Methodology
% Generic for any Technology
%
% Author      : Hassan Shehata Ali
% Institution : Mansoura University
% Date        : March 2026
%
% Acknowledgment: lookup / lookupVGS functions by Prof. Boris Murmann
%                 (Stanford University).
%
% KEYBOARD SHORTCUTS (focus any plot window):
%   V  -- drop a draggable vertical marker  (all linked axes)
%   H  -- drop a draggable horizontal marker
%   C  -- clear all markers
%   T  -- toggle NMOS / PMOS
%   F  -- Figure-of-Merit  (multi-FoM + FoM vs L subplot)
%   P  -- custom plot (multi-Y overlay, dual y-axis)
%   S  -- auto-sizing   (explicit gm/ID input field)
%   D  -- exact sizing  (find L & W for target gain)
%   I  -- complete transistor profiler
%   E  -- export last report to Design_Log.txt
% =========================================================================

clear; close all; clc;

%% 1. Load Technology Data
load('tech_nch.mat');
load('tech_pch.mat');

% PMOS: absolute values (avoid sign issues in interpolation)
for fn = fieldnames(pch)'
    if isnumeric(pch.(fn{1}))
        pch.(fn{1}) = abs(pch.(fn{1}));
    end
end

%% 2. Global Colour / Style Palette
CLR.bg         = [0.10  0.12  0.16];
CLR.panel      = [0.14  0.17  0.22];
CLR.grid       = [0.25  0.28  0.35];
CLR.ax_fg      = [0.88  0.90  0.94];
CLR.nmos_lines = {[0.27 0.73 1.00];
                  [0.00 0.53 0.90];
                  [0.40 0.85 1.00];
                  [0.60 0.90 1.00]};
CLR.pmos_lines = {[1.00 0.42 0.42];
                  [0.95 0.25 0.25];
                  [1.00 0.65 0.35];
                  [1.00 0.80 0.40]};
CLR.marker_v   = [1.00 0.82 0.20];
CLR.marker_h   = [0.35 1.00 0.60];
CLR.op_dot     = [1.00 0.35 0.35];
CLR.accent     = [0.27 0.73 1.00];

%% 3. State Struct
State.nch              = nch;
State.pch              = pch;
State.current_dev      = 'nch';
State.L_array          = [0.09,0.5,1];
State.VDS_target       = 0.6;
State.gm_id_range      = 5:0.5:25;
State.last_design_report = 'No design generated yet.';
State.CLR              = CLR;

%% 4. Launch
fig = figure('Name','UMC 90nm  |  gm/ID Design Space', ...
             'Position',[80 120 1280 420], ...
             'Color', CLR.bg);
setappdata(fig,'State',State);
update_main_plots(fig);

% =========================================================================
%  MAIN PLOT
% =========================================================================
function update_main_plots(fig)
    clf(fig);
    set(fig,'WindowKeyPressFcn',@(f,e) cadence_shortcuts(f,e));

    State    = getappdata(fig,'State');
    CLR      = State.CLR;
    dev_data = State.(State.current_dev);
    L        = State.L_array;
    VDS      = State.VDS_target;
    gmid     = State.gm_id_range;
    isN      = strcmp(State.current_dev,'nch');
    dlabel   = 'NMOS'; if ~isN, dlabel='PMOS'; end
    colors   = CLR.nmos_lines; if ~isN, colors=CLR.pmos_lines; end

    set(fig,'Name',sprintf('UMC 90nm  |  gm/ID Design Space  [%s]  VDS=%.2fV', dlabel, VDS));

    nL  = numel(L);
    leg = cell(1,nL);
    for k=1:nL, leg{k}=sprintf('L = %g um', L(k)); end

    titles = {'Transit Frequency  f_T', ...
              'Intrinsic Gain  g_m/g_{ds}', ...
              'Current Density  I_D/W'};
    ylabs  = {'f_T  (GHz)', 'Gain  (V/V)', 'I_D/W  (A/um)'};

    for sp = 1:3
        ax = subplot(1,3,sp);
        style_axes(ax, CLR);
        hold(ax,'on');

        for k = 1:nL
            c = colors{mod(k-1,numel(colors))+1};
            switch sp
                case 1
                    yd = lookup(dev_data,'GM_CGG','GM_ID',gmid,'L',L(k),'VDS',VDS)/(2*pi*1e9);
                case 2
                    yd = lookup(dev_data,'GM_GDS','GM_ID',gmid,'L',L(k),'VDS',VDS);
                case 3
                    yd = lookup(dev_data,'ID_W',  'GM_ID',gmid,'L',L(k),'VDS',VDS);
            end
            plot(ax, gmid, yd, 'Color',c, 'LineWidth',2.2, 'Tag','data_curve');
        end

        if sp==3, set(ax,'YScale','log'); end

        xlabel(ax,'g_m/I_D  (1/V)','Color',CLR.ax_fg,'FontSize',10);
        ylabel(ax, ylabs{sp},      'Color',CLR.ax_fg,'FontSize',10);
        title(ax,  titles{sp},     'Color',CLR.ax_fg,'FontSize',11,'FontWeight','bold');

        lg = legend(ax, leg, 'Location','best');
        set(lg,'TextColor',CLR.ax_fg,'Color',CLR.panel,'EdgeColor',CLR.grid,'FontSize',8.5);
    end

    all_ax = findobj(fig,'Type','axes');
    linkaxes(all_ax,'x');

    annotation(fig,'textbox',[0 0.01 1 0.04], ...
        'String', sprintf('[%s]   VDS = %.2fV   |   Press: V H C T F P S D I E', dlabel, VDS), ...
        'Color',[0.55 0.65 0.75], 'FontSize',8.5, 'EdgeColor','none', ...
        'HorizontalAlignment','center','VerticalAlignment','middle');
end

% =========================================================================
%  KEYBOARD DISPATCHER
% =========================================================================
function cadence_shortcuts(fig, event)
    State    = getappdata(fig,'State');
    CLR      = State.CLR;
    dev_data = State.(State.current_dev);
    ax       = gca;
    pt       = get(ax,'CurrentPoint');
    x_val    = pt(1,1);
    all_axes = findobj(fig,'Type','axes');
    cid      = sprintf('%08x', mod(round(rand*1e8),2^31));

    switch lower(event.Key)

        % ================================================================
        case 'v'
            for i = 1:numel(all_axes)
                xl = xline(all_axes(i), x_val, ...
                    'Color',CLR.marker_v, 'LineWidth',1.8, ...
                    'Label',sprintf('  gm/ID=%.2f  ',x_val), ...
                    'Tag',['v_cursor_' cid]);
                xl.ButtonDownFcn = @(s,~) startDragV(s,fig,cid);
                n_curves_v = numel(findobj(all_axes(i),'Tag','data_curve'));
                for jv = 1:n_curves_v
                    plot(all_axes(i),NaN,NaN,'o','Color',CLR.marker_v, ...
                        'MarkerFaceColor',CLR.marker_v,'MarkerSize',6, ...
                        'Tag',['v_mark_' cid]);
                    text(all_axes(i),NaN,NaN,'','Color',CLR.marker_v, ...
                        'BackgroundColor',CLR.panel,'EdgeColor',CLR.marker_v, ...
                        'Tag',['v_text_' cid],'FontSize',8,'Margin',2, ...
                        'VerticalAlignment','bottom');
                end
            end
            updateVI(fig,cid,x_val);

        % ================================================================
        case 'h'
            y_val = pt(1,2);
            yl = yline(ax, y_val, ...
                'Color',CLR.marker_h, 'LineWidth',1.8, ...
                'Label',sprintf('  y=%.3g  ',y_val), ...
                'Tag',['h_cursor_' cid]);
            yl.ButtonDownFcn = @(s,~) startDragH(s,fig,cid);
            n_curves_h = numel(findobj(ax,'Tag','data_curve'));
            for jh = 1:n_curves_h
                plot(ax,NaN,NaN,'o','Color',CLR.marker_h, ...
                    'MarkerFaceColor',CLR.marker_h,'MarkerSize',6, ...
                    'Tag',['h_mark_' cid]);
                text(ax,NaN,NaN,'','Color',CLR.marker_h, ...
                    'BackgroundColor',CLR.panel,'EdgeColor',CLR.marker_h, ...
                    'Tag',['h_text_' cid],'FontSize',8,'Margin',2, ...
                    'VerticalAlignment','bottom');
            end
            updateHI(ax,cid,y_val);

        % ================================================================
        case 'c'
            delete(findobj(fig,'-regexp','Tag','^(v_|h_)'));

        % ================================================================
        case 't'
            if strcmp(State.current_dev,'nch')
                State.current_dev = 'pch';
                fprintf('---> Switched to PMOS\n');
            else
                State.current_dev = 'nch';
                fprintf('---> Switched to NMOS\n');
            end
            setappdata(fig,'State',State);
            update_main_plots(fig);

        % ================================================================
        % KEY F ? Speed FoM and Gain-Speed FoM, side by side
        %   fi=1  Speed      : (gm/ID) * fT           [GHz/V]
        %   fi=2  Gain-Speed : (gm/ID) * fT * sqrt(Av)[GHz*V^-0.5]
        %   Each plot has its own y-axis scale and colour.
        %   Peak marker (?) + gm/ID label on every curve.
        % ================================================================
        case 'f'
            gmid  = State.gm_id_range;
            nL    = numel(State.L_array);
            isN   = strcmp(State.current_dev,'nch');

            fom_titles = { ...
                'Speed FoM  \rm(g_m/I_D \times f_T)', ...
                'Gain-Speed FoM  \rm(g_m/I_D \times f_T \times \surdA_v)'};
            fom_ylbls  = {'GHz/V', 'GHz \cdot V^{-0.5}'};
            fom_colors = {[0.27 0.73 1.00], [0.40 0.90 0.50]};
            if ~isN
                fom_colors = {[1.00 0.42 0.42], [1.00 0.70 0.30]};
            end

            ff = figure('Name', sprintf('Figures of Merit  [%s]  VDS=%.2fV', ...
                        upper(State.current_dev), State.VDS_target), ...
                        'Color',CLR.bg,'Position',[80 80 1200 560], ...
                        'NumberTitle','off');
            set(ff,'WindowKeyPressFcn',@(f,e) cadence_shortcuts(f,e));
            setappdata(ff,'State',State);

            % Two side-by-side plots; x-axes linked
            ax_pos = {[0.055 0.12 0.430 0.80], [0.540 0.12 0.430 0.80]};
            line_styles = {'-','--',':','-.'};
            ax_fom = gobjects(1,2);

            for fi = 1:2
                ax = axes('Parent',ff,'Units','normalized', ...
                          'OuterPosition', ax_pos{fi});
                style_axes_pro(ax, CLR);
                hold(ax,'on');
                ax_fom(fi) = ax;

                fom_col = fom_colors{fi};

                for k = 1:nL
                    Lk  = State.L_array(k);
                    fom = compute_fom(dev_data, gmid, Lk, State.VDS_target, fi);
                    if all(isnan(fom)), continue; end

                    ls      = line_styles{mod(k-1,4)+1};
                    lw      = max(2.4 - 0.3*(k-1), 1.4);
                    % Lighten colour for successive L values
                    alpha_l = 0.55 + 0.45*(k/max(nL,1));
                    c_plot  = min(fom_col*alpha_l + (1-alpha_l)*CLR.panel, 1);

                    plot(ax, gmid, fom, ...
                         'Color',c_plot,'LineWidth',lw,'LineStyle',ls, ...
                         'DisplayName',sprintf('L = %g \xb5m', Lk), ...
                         'Tag','data_curve');

                    % Peak marker
                    valid = ~isnan(fom);
                    if ~any(valid), continue; end
                    [pk_val, pk_idx] = max(fom(valid));
                    gv    = gmid(valid);
                    pk_gm = gv(pk_idx);

                    plot(ax, pk_gm, pk_val, 'v', ...
                         'Color',c_plot,'MarkerFaceColor',c_plot, ...
                         'MarkerEdgeColor',[1 1 1],'MarkerSize',10, ...
                         'LineWidth',1.3,'HandleVisibility','off');

                    % Peak gm/ID label
                    yl_now  = ylim(ax);
                    y_nudge = 0.045 * max(abs(yl_now(2)-yl_now(1)), eps);
                    text(ax, pk_gm, pk_val + y_nudge, ...
                         sprintf('%.1f', pk_gm), ...
                         'Color',c_plot,'FontSize',9,'FontWeight','bold', ...
                         'BackgroundColor',CLR.bg,'Margin',1, ...
                         'HorizontalAlignment','center','VerticalAlignment','bottom');
                end

                xlabel(ax,'g_m/I_D  (1/V)','Color',CLR.ax_fg,'FontSize',11);
                ylabel(ax, fom_ylbls{fi},  'Color',fom_col,  'FontSize',11);
                set(ax,'YColor',fom_col);
                title(ax, fom_titles{fi}, ...
                      'Color',fom_col,'FontSize',12,'FontWeight','bold', ...
                      'Interpreter','tex');

                if nL > 1
                    lg_f = legend(ax,'Location','best');
                    set(lg_f,'TextColor',CLR.ax_fg,'Color',CLR.panel, ...
                             'EdgeColor',CLR.grid,'FontSize',9);
                end
            end

            linkaxes(ax_fom,'x');

            annotation(ff,'textbox',[0 0.002 1 0.040], ...
                'String', sprintf('[%s]   V_{DS} = %.2fV   |   (v) markers show peak g_m/I_D per curve', ...
                    upper(State.current_dev), State.VDS_target), ...
                'Color',[0.50 0.60 0.70],'FontSize',9,'EdgeColor','none', ...
                'HorizontalAlignment','center','VerticalAlignment','middle');

        % ================================================================
        % KEY P ? Arbitrary X/Y custom plot
        %   Dialog presents two listboxes: Y-variables and X-variables.
        %   Any pairing is valid.  Multi-Y selection ? dual y-axis.
        % ================================================================
        case 'p'
            [sel_y_keys, sel_x_key, cust_L, cust_vds, dlg_ok] = ...
                arbitrary_xy_dialog(CLR, State.VDS_target);
            if ~dlg_ok, return; end

            isN    = strcmp(State.current_dev,'nch');
            colors = CLR.nmos_lines; if ~isN, colors=CLR.pmos_lines; end
            gmid   = State.gm_id_range;

            % sel_y_keys = {left_cell, right_cell}
            grp1     = sel_y_keys{1};
            grp2     = sel_y_keys{2};
            use_dual = ~isempty(grp2);

            nf = figure('Name', sprintf('Custom Plot  [%s]  X=%s', ...
                        upper(State.current_dev), sel_x_key), ...
                        'Color',CLR.bg,'Position',[100 80 940 580], ...
                        'NumberTitle','off');
            set(nf,'WindowKeyPressFcn',@(f,e) cadence_shortcuts(f,e));
            setappdata(nf,'State',State);

            ax_L = axes('Parent',nf);
            style_axes(ax_L, CLR);
            hold(ax_L,'on');

            if use_dual
                ax_R = axes('Parent',nf);
                style_axes(ax_R, CLR);
                hold(ax_R,'on');
                set(ax_R,'Color','none','YAxisLocation','right', ...
                         'XTickLabel',[],'GridLineStyle','none');
                set(ax_L,'Units','normalized');
                set(ax_R,'Units','normalized','Position',get(ax_L,'Position'));
            end

            % Log scale for quantities that span decades
            log_fields = {'ID_W','ID','CGG_W','CGD_W','CDD_W','CSS_W', ...
                          'CGG','CGD','CDD','CSS','GM','GMB','GDS','RO'};

            right_colors = {[1.00 0.65 0.20],[1.00 0.80 0.10], ...
                            [0.95 0.45 0.10],[1.00 0.90 0.30]};

            for grp_idx = 1 : (1 + use_dual)
                cur_ax   = ax_L;   cur_vars = grp1;  cur_cols = colors;
                if grp_idx == 2
                    cur_ax   = ax_R;   cur_vars = grp2;  cur_cols = right_colors;
                end

                log_flag = false;
                for vi = 1:numel(cur_vars)
                    yv  = cur_vars{vi};
                    col = cur_cols{mod(vi-1,numel(cur_cols))+1};
                    for k = 1:numel(cust_L)
                        ls = line_style_for(k);
                        try
                            [yd, x_vec] = fetch_plot_data_xy(dev_data, yv, ...
                                          sel_x_key, gmid, cust_L(k), cust_vds);
                        catch ME
                            errordlg(sprintf('Lookup failed (%s vs %s, L=%g):\n%s', ...
                                     yv, sel_x_key, cust_L(k), ME.message),'Plot Error');
                            close(nf); return;
                        end
                        % Use clean display name (not the raw key)
                        plot(cur_ax, x_vec, yd, ...
                             'Color',col,'LineWidth',2.2,'LineStyle',ls, ...
                             'DisplayName',sprintf('%s  L=%g', yv, cust_L(k)), ...
                             'Tag','data_curve');
                    end
                    if any(strcmpi(yv, log_fields)), log_flag = true; end
                end

                if log_flag, set(cur_ax,'YScale','log'); end

                ylbl = strjoin(cur_vars,' / ');
                if grp_idx == 1
                    ylabel(cur_ax, ylbl,'Color',CLR.ax_fg,'FontSize',11);
                else
                    ylabel(cur_ax, ylbl,'Color',[1.00 0.65 0.20],'FontSize',11);
                    set(cur_ax,'YColor',[1.00 0.65 0.20]);
                end
            end

            % X label
            switch upper(sel_x_key)
                case 'GMID', x_display = 'g_m/I_D  (1/V)';
                case 'VGS',  x_display = 'V_{GS}  (V)';
                otherwise,   x_display = sel_x_key;
            end
            xlabel(ax_L, x_display,'Color',CLR.ax_fg,'FontSize',11);

            y_title = strjoin(grp1, ', ');
            if use_dual
                y_title = [y_title '  |  ' strjoin(grp2, ', ')];
            end
            title(ax_L, sprintf('%s  vs  %s    V_{DS}=%.2fV  [%s]', ...
                y_title, sel_x_key, cust_vds, upper(State.current_dev)), ...
                'Color',CLR.ax_fg,'FontSize',11,'FontWeight','bold');

            lg = legend(ax_L,'Location','best');
            set(lg,'TextColor',CLR.ax_fg,'Color',CLR.panel, ...
                   'EdgeColor',CLR.grid,'FontSize',9);

        % ================================================================
        % KEY S ? Auto-Sizing (explicit gm/ID input)
        % ================================================================
        case 's'
            % --- Dialog: gm/ID is now an explicit input (not from cursor) ---
            ans_ = inputdlg( ...
                {'g_m/I_D   (1/V)  e.g.  15:', ...
                 'Target g_m   (e.g.  500u  or  1m  or  0.5m):'}, ...
                'Auto-Sizing',[1 55], ...
                {sprintf('%.1f', x_val), ''});
            if isempty(ans_), return; end

            tgt_gmid = str2double(ans_{1});
            tgt_gm   = parse_eng(ans_{2});

            if isnan(tgt_gmid) || tgt_gmid <= 0
                errordlg(['Enter a positive gm/ID value.' char(10) ...
                    'Example:  15  (units: 1/V)'], 'Input Error');
                return;
            end
            if isnan(tgt_gm) || tgt_gm <= 0
                errordlg(['Enter gm with engineering prefix.' char(10) ...
                    'Examples:  500u = 500 uS' char(10) ...
                    '           1m   = 1 mS' char(10) ...
                    '           0.001 = 1 mS'], 'Input Error');
                return;
            end

            ID_req = tgt_gm / tgt_gmid;

            rows = {};
            for k = 1:numel(State.L_array)
                idw = lookup(dev_data,'ID_W','GM_ID',tgt_gmid, ...
                             'L',State.L_array(k),'VDS',State.VDS_target);
                if abs(idw) < 1e-15
                    errordlg(sprintf('ID_W ~ 0 at gm/ID=%.1f L=%.3f: invalid operating point.', ...
                             tgt_gmid, State.L_array(k)),'Division Error');
                    return;
                end
                W    = ID_req / idw;
                vgs  = lookupVGS(dev_data,'GM_ID',tgt_gmid, ...
                                 'L',State.L_array(k),'VDS',State.VDS_target);
                cggw = lookup(dev_data,'CGG_W','GM_ID',tgt_gmid, ...
                              'L',State.L_array(k),'VDS',State.VDS_target);
                fT   = tgt_gm / (2*pi*(cggw*W));
                rows{end+1} = sprintf(' %-8s  %-8s  %-8s  %-8s  %-8s  %-8s', ...
                    eng(State.L_array(k)*1e-6,'m'), eng(W*1e-6,'m'), ...
                    eng(ID_req,'A'), eng(vgs,'V'), eng(cggw*W,'F'), eng(fT,'Hz')); %#ok<AGROW>
            end
            hdr = sprintf('%-8s  %-8s  %-8s  %-8s  %-8s  %-8s', ...
                'L','W','ID','VGS','Cgg','fT');
            rep = build_report('AUTO-SIZING REPORT', ...
                sprintf('Target gm=%s  |  gm/ID=%.1f V^-1  |  ID=%s', ...
                    eng(tgt_gm,'S'), tgt_gmid, eng(ID_req,'A')), ...
                upper(State.current_dev), hdr, rows);
            fprintf('\n%s',rep);
            State.last_design_report = rep;
            setappdata(fig,'State',State);
            show_text_window(rep,'Auto-Sizing Report',CLR);

        % ================================================================
        case 'd'
            ans_ = inputdlg( ...
                {'gm/ID  (1/V):', ...
                 'I_D   (e.g.  10u  50u  1m):', ...
                 'V_DS  (e.g.  600m  or  0.6):', ...
                 'Target Gain  (V/V):'}, ...
                'Exact Sizing',[1 50], ...
                {num2str(round(x_val,1)),'','',''});
            if isempty(ans_), return; end
            req_gmid = str2double(ans_{1});
            req_id   = parse_eng(ans_{2});
            req_vds  = parse_eng(ans_{3});
            req_gain = str2double(ans_{4});
            if isnan(req_gmid) || isnan(req_id) || isnan(req_vds) || isnan(req_gain)
                errordlg(['All fields required.' char(10) ...
                    'Use engineering prefixes: 10u 50u 1m 600m' char(10) ...
                    'or plain SI values: 0.00001 0.6'], 'Input Error');
                return;
            end
            if req_gmid<=0 || req_id<=0 || req_vds<=0 || req_gain<=0
                errordlg('All values must be positive.','Input Error');
                return;
            end

            dense_L = 0.06:0.005:1.0;
            gain_L  = lookup(dev_data,'GM_GDS','GM_ID',req_gmid,'L',dense_L,'VDS',req_vds);

            body = '';
            if req_gain < min(gain_L) || req_gain > max(gain_L)
                body = sprintf( ...
                    ' [WARNING] Gain %.1f V/V is not achievable at gm/ID=%.1f\n Achievable range: %.1f ... %.1f V/V', ...
                    req_gain, req_gmid, min(gain_L), max(gain_L));
            else
                [gu,si] = unique(gain_L);  Lu = dense_L(si);
                req_L   = interp1(gu,Lu,req_gain,'linear');
                idw     = lookup(dev_data,'ID_W','GM_ID',req_gmid,'L',req_L,'VDS',req_vds);
                if abs(idw) < 1e-15
                    errordlg('ID_W ~ 0: operating point outside valid LUT region.','Division Error');
                    return;
                end
                req_W   = req_id/idw;
                req_vgs = lookupVGS(dev_data,'GM_ID',req_gmid,'L',req_L,'VDS',req_vds);
                req_gm  = req_gmid*req_id;
                cggw    = lookup(dev_data,'CGG_W','GM_ID',req_gmid,'L',req_L,'VDS',req_vds);
                req_fT  = req_gm/(2*pi*cggw*req_W);
                body = sprintf( ...
                    ' L        : %s\n W        : %s\n g_m      : %s\n V_GS     : %s\n f_T      : %s\n Gain     : %.3f V/V  (%.1f dB)', ...
                    eng(req_L*1e-6,'m'), eng(req_W*1e-6,'m'), eng(req_gm,'S'), ...
                    eng(req_vgs,'V'), eng(req_fT,'Hz'), req_gain, 20*log10(req_gain));
            end
            rep = build_report('EXACT SIZING REPORT', ...
                sprintf('gm/ID=%.1f  ID=%s  VDS=%s  Gain=%.1fV/V', ...
                    req_gmid, eng(req_id,'A'), eng(req_vds,'V'), req_gain), ...
                upper(State.current_dev), '', {body});
            fprintf('\n%s',rep);
            State.last_design_report = rep;
            setappdata(fig,'State',State);

            if req_gain < min(gain_L) || req_gain > max(gain_L)
                show_text_window(rep,'Exact Sizing Report',CLR);
            else
                gmv  = State.gm_id_range;
                fTv  = lookup(dev_data,'GM_CGG','GM_ID',gmv,'L',req_L,'VDS',req_vds)/(2*pi);
                Avv  = lookup(dev_data,'GM_GDS','GM_ID',gmv,'L',req_L,'VDS',req_vds);
                idwv = lookup(dev_data,'ID_W',  'GM_ID',gmv,'L',req_L,'VDS',req_vds);
                FoMv = gmv(:).*fTv(:)/1e9;
                show_sizing_window(State, rep, ...
                    req_gmid, req_id, req_L, req_vds, req_W, req_vgs, ...
                    req_gm, req_fT, req_gain, ...
                    dense_L, gain_L, ...
                    gmv, fTv, Avv, idwv, FoMv, CLR);
            end

        % ================================================================
        case 'i'
            ans_ = inputdlg( ...
                {'gm/ID  (1/V):', ...
                 'I_D   (e.g.  10u  50u  1m):', ...
                 'L     (e.g.  500n  1u  100n):', ...
                 'V_DS  (e.g.  600m  or  0.6):', ...
                 'V_SB  (e.g.  0  or  100m):'}, ...
                'Transistor Profiler',[1 50], ...
                {'','','','',''});
            if isempty(ans_), return; end
            req_gmid  = str2double(ans_{1});
            req_id    = parse_eng(ans_{2});
            req_L_si  = parse_eng(ans_{3});
            req_L     = req_L_si * 1e6;
            req_vds   = parse_eng(ans_{4});
            req_vsb_v = strtrim(ans_{5});
            if isempty(req_vsb_v) || strcmp(req_vsb_v,'0')
                req_vsb = 0;
            else
                req_vsb = parse_eng(req_vsb_v);
            end
            if any(isnan([req_gmid, req_id, req_L, req_vds]))
                errordlg(['All fields are required.' char(10) ...
                    'Use engineering prefixes:' char(10) ...
                    '  I_D: 10u  50u  1m' char(10) ...
                    '  L:   500n  1u  100n' char(10) ...
                    '  VDS: 600m  or  0.6'], 'Input Error');
                return;
            end
            if req_gmid <= 0 || req_id <= 0 || req_L <= 0 || req_vds <= 0
                errordlg('gm/ID, I_D, L, and V_DS must all be positive.','Input Error');
                return;
            end

            L_min = min(dev_data.L); L_max = max(dev_data.L);
            V_min = min(dev_data.VDS); V_max = max(dev_data.VDS);
            if req_L < L_min || req_L > L_max
                errordlg(sprintf('L=%.4f um is outside LUT range [%.4f, %.4f] um.', ...
                    req_L, L_min, L_max),'LUT Boundary Error');
                return;
            end
            if req_vds < V_min || req_vds > V_max
                errordlg(sprintf('VDS=%.3f V is outside LUT range [%.3f, %.3f] V.', ...
                    req_vds, V_min, V_max),'LUT Boundary Error');
                return;
            end

            try
                id_w = lookup(dev_data,'ID_W','GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                if abs(id_w) < 1e-15
                    errordlg(sprintf('ID_W ~ 0 at gm/ID=%.1f L=%.3f VDS=%.2f: invalid operating point.', ...
                             req_gmid,req_L,req_vds),'Division Error');
                    return;
                end
                req_W   = req_id / id_w;
                req_vgs = lookupVGS(dev_data,'GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_vth = lookup(dev_data,'VT','VGS',req_vgs,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_id_raw  = lookup(dev_data,'ID','VGS',req_vgs,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_gm_raw  = lookup(dev_data,'GM','VGS',req_vgs,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_vdsat   = 2 * req_id_raw / req_gm_raw;
                req_gm    = req_gmid * req_id;
                gain      = lookup(dev_data,'GM_GDS','GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_gds   = req_gm / gain;
                cgg_w     = lookup(dev_data,'CGG_W','GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                cgd_w     = lookup(dev_data,'CGD_W','GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                cdd_w     = lookup(dev_data,'CDD_W','GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_cgg   = abs(cgg_w)*req_W;
                req_cgd   = abs(cgd_w)*req_W;
                req_cdd   = abs(cdd_w)*req_W;

                lut_vals = [id_w, req_vgs, req_vth, req_gm, gain, req_cgg, req_cgd, req_cdd];
                if any(isnan(lut_vals) | isinf(lut_vals))
                    errordlg(sprintf(['One or more LUT lookups returned NaN/Inf at\n' ...
                        'gm/ID=%.1f  L=%.3f um  VDS=%.2f V.\n' ...
                        'Operating point may be outside the valid LUT region.'], ...
                        req_gmid, req_L, req_vds),'Invalid Operating Point');
                    return;
                end

                gm_cgg_op = lookup(dev_data,'GM_CGG','GM_ID',req_gmid,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                req_fT    = gm_cgg_op / (2*pi);
                req_vov   = req_vgs - req_vth;

                gmv  = State.gm_id_range;
                fTv  = lookup(dev_data,'GM_CGG','GM_ID',gmv,'L',req_L,'VDS',req_vds,'VSB',req_vsb)/(2*pi);
                Avv  = lookup(dev_data,'GM_GDS','GM_ID',gmv,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                idwv = lookup(dev_data,'ID_W',  'GM_ID',gmv,'L',req_L,'VDS',req_vds,'VSB',req_vsb);
                FoMv = gmv(:).*fTv(:)/1e9;
            catch ME
                errordlg(sprintf('Profiler lookup failed:\n%s',ME.message),'Error');
                return;
            end

            rep = build_profiler_report(State.current_dev, ...
                req_gmid, req_id, req_L, req_vds, req_vsb, ...
                req_W, req_vgs, req_vth, req_vov, req_vdsat, ...
                req_gm, req_gds, gain, req_fT, ...
                req_cgg, req_cgd, req_cdd);

            fprintf('\n%s',rep);
            State.last_design_report = rep;
            setappdata(fig,'State',State);

            show_profiler_window(State, rep, ...
                req_gmid, req_id, req_L, req_vds, req_vsb, ...
                req_W, req_vgs, req_vth, req_vov, req_vdsat, ...
                req_fT, gain, req_gm, req_gds, ...
                req_cgg, req_cgd, req_cdd, ...
                gmv, fTv, Avv, idwv, FoMv);

        % ================================================================
        case 'e'
            if strcmp(State.last_design_report,'No design generated yet.')
                errordlg('Generate a design first (S, D, or I).','Export Error');
                return;
            end
            ans_ = inputdlg({'Block name (e.g. M1_TailCurrent):'}, ...
                'Export Log',[1 40],{'M1_Block'});
            if isempty(ans_), return; end
            fid = fopen('Design_Log.txt','a');
            fprintf(fid,'\n%s\n BLOCK: %s  |  DEV: %s  |  %s\n', ...
                repmat('=',1,65), upper(strtrim(ans_{1})), ...
                upper(State.current_dev), datestr(now,'yyyy-mm-dd HH:MM'));
            fprintf(fid,'%s',State.last_design_report);
            fclose(fid);
            fprintf('---> Appended to Design_Log.txt\n');
    end
end

% =========================================================================
%  HELPER ? compute_fom
%  Returns FoM vector over gmid for a given L, VDS and FoM index (1-4).
%  fi: 1=Speed, 2=Gain-Speed, 3=Power, 4=Noise
% =========================================================================
function fom = compute_fom(dev_data, gmid, L, VDS, fi)
    try
        fT_raw  = lookup(dev_data,'GM_CGG','GM_ID',gmid,'L',L,'VDS',VDS) / (2*pi*1e9); % GHz
        Av      = lookup(dev_data,'GM_GDS','GM_ID',gmid,'L',L,'VDS',VDS);              % V/V
        idw     = lookup(dev_data,'ID_W',  'GM_ID',gmid,'L',L,'VDS',VDS);              % A/um

        Av(Av <= 0)  = NaN;
        idw(idw <= 0)= NaN;

        switch fi
            case 1   % Speed FoM
                fom = gmid(:)' .* fT_raw(:)';              % [GHz/V]
            case 2   % Gain-Speed FoM
                fom = gmid(:)' .* fT_raw(:)' .* sqrt(Av(:)');  % [GHz * V^-0.5]
            case 3   % Power FoM
                fom = (gmid(:)').^2 ./ idw(:)';            % [(V^2 A/um)^-1]  unit kept relative
            case 4   % Noise proxy FoM
                fom = gmid(:)' .* sqrt(Av(:)') ./ fT_raw(:)';  % [V^-1 GHz^-1]
            otherwise
                fom = nan(size(gmid));
        end
        fom(isnan(fom)|isinf(fom)) = NaN;
    catch
        fom = nan(size(gmid));
    end
end

% =========================================================================
%  HELPER ? line_style_for(k)
% =========================================================================
function ls = line_style_for(k)
    styles = {'-','--',':','-.'};
    ls = styles{mod(k-1,4)+1};
end

% =========================================================================
%  HELPER ? fetch_plot_data_xy
%  Returns [yd, x_vec] for a unified (y_key, x_var) pairing.
%
%  y_key is the short canonical name from Y_params (VT, VGS, VOV, VDSAT,
%  RO, GM_GDS, GM_CGG, ID_W, CGG_W ? GM, GDS, CGG, CGD, CDD, CSS, ID, GMID).
%
%  x_var: 'GMID' or 'VGS'
%
%  The function maps each y_key to the correct LUT call depending on x_var:
%    GMID axis  ? direct LUT ratio fields, or two-step composed path
%    VGS  axis  ? raw VGS-indexed fields
% =========================================================================
function [yd, x_vec] = fetch_plot_data_xy(dev_data, y_key, x_var, gmid, L, vds)
    W_ref       = dev_data.W;
    norm_fields = {'ID','GM','GMB','GDS','CGG','CGD','CDD','CSS'};

    switch upper(x_var)
        case 'GMID',  x_vec = gmid(:)';
        case 'VGS',   x_vec = linspace(min(dev_data.VGS), max(dev_data.VGS), 301);
        otherwise,    error('Unknown X variable: %s', x_var);
    end

    switch upper(x_var)

        % ==============================================================
        % X = gm/ID
        % ==============================================================
        case 'GMID'
            % Direct ratio fields ? already indexed on gm/ID in LUT
            direct_gmid = {'GM_GDS','GM_CGG','ID_W','CGG_W','CGD_W','CDD_W','CSS_W'};
            if any(strcmpi(y_key, direct_gmid))
                yd = lookup(dev_data, y_key, 'GM_ID', x_vec, 'L', L, 'VDS', vds);
                if strcmpi(y_key,'GM_CGG'), yd = yd/(2*pi*1e9); end  % -> GHz

            else
                % Two-step: invert gm/ID -> VGS, then look up field at VGS
                vgs_c = arrayfun(@(gid) lookupVGS(dev_data,'GM_ID',gid, ...
                                 'L',L,'VDS',vds,'VSB',0), x_vec);
                switch upper(y_key)
                    case 'VGS'
                        yd = vgs_c;
                    case 'VT'
                        yd = arrayfun(@(vg) lookup(dev_data,'VT','VGS',vg, ...
                                     'L',L,'VDS',vds), vgs_c);
                    case 'VOV'
                        vt_c = arrayfun(@(vg) lookup(dev_data,'VT','VGS',vg, ...
                                        'L',L,'VDS',vds), vgs_c);
                        yd   = vgs_c - vt_c;
                    case 'VDSAT'
                        id_c = arrayfun(@(vg) lookup(dev_data,'ID','VGS',vg, ...
                                        'L',L,'VDS',vds), vgs_c);
                        gm_c = arrayfun(@(vg) lookup(dev_data,'GM','VGS',vg, ...
                                        'L',L,'VDS',vds), vgs_c);
                        yd   = 2*id_c./gm_c;
                    case 'RO'
                        gain_c = lookup(dev_data,'GM_GDS','GM_ID',x_vec,'L',L,'VDS',vds);
                        id_c   = lookup(dev_data,'ID_W',  'GM_ID',x_vec,'L',L,'VDS',vds)*W_ref;
                        gm_c   = x_vec .* id_c;
                        yd     = 1./(gm_c./gain_c)/W_ref;
                    case {'GM','GMB','GDS','CGG','CGD','CDD','CSS'}
                        % Raw VGS-indexed small-signal / cap field, norm per width
                        yd = arrayfun(@(vg) lookup(dev_data,y_key,'VGS',vg, ...
                                     'L',L,'VDS',vds), vgs_c);
                        yd = yd / W_ref;
                    case {'ID','GMID'}
                        % ID and gm/ID are naturally functions of VGS only
                        id_r = lookup(dev_data,'ID','VGS',vgs_c,'L',L,'VDS',vds);
                        gm_r = lookup(dev_data,'GM','VGS',vgs_c,'L',L,'VDS',vds);
                        if strcmpi(y_key,'ID')
                            yd = id_r / W_ref;
                        else
                            yd = gm_r ./ id_r;
                            yd(isnan(yd)|isinf(yd)|yd<0) = NaN;
                        end
                    otherwise
                        error('Y key "%s" not supported for X=GMID', y_key);
                end
            end

        % ==============================================================
        % X = VGS
        % ==============================================================
        case 'VGS'
            switch upper(y_key)
                case 'GMID'
                    id_r = lookup(dev_data,'ID','VGS',x_vec,'L',L,'VDS',vds);
                    gm_r = lookup(dev_data,'GM','VGS',x_vec,'L',L,'VDS',vds);
                    yd   = gm_r ./ id_r;
                    yd(isnan(yd)|isinf(yd)|yd<0) = NaN;
                case 'VT'
                    yd = lookup(dev_data,'VT','VGS',x_vec,'L',L,'VDS',vds);
                case 'VOV'
                    vt_r = lookup(dev_data,'VT','VGS',x_vec,'L',L,'VDS',vds);
                    yd   = x_vec - vt_r;
                case 'VDSAT'
                    id_r = lookup(dev_data,'ID','VGS',x_vec,'L',L,'VDS',vds);
                    gm_r = lookup(dev_data,'GM','VGS',x_vec,'L',L,'VDS',vds);
                    yd   = 2*id_r./gm_r;
                case 'VGS'
                    yd = x_vec;   % trivial: VGS vs VGS = identity (not useful, but safe)
                case 'RO'
                    gm_r  = lookup(dev_data,'GM', 'VGS',x_vec,'L',L,'VDS',vds);
                    gds_r = lookup(dev_data,'GDS','VGS',x_vec,'L',L,'VDS',vds);
                    yd    = gm_r ./ gds_r ./ gm_r / W_ref;  % = 1/(gds/W)
                    yd    = 1./(gds_r/W_ref);
                case {'GM','GMB','GDS','CGG','CGD','CDD','CSS'}
                    yd = lookup(dev_data, y_key,'VGS',x_vec,'L',L,'VDS',vds);
                    yd = yd / W_ref;
                case 'ID'
                    yd = lookup(dev_data,'ID','VGS',x_vec,'L',L,'VDS',vds) / W_ref;
                % Derived ratio fields ? use gm/ID-indexed LUT at representative point
                case {'GM_GDS','GM_CGG','ID_W','CGG_W','CGD_W','CDD_W','CSS_W'}
                    % These are indexed on gm/ID; not naturally swept vs VGS.
                    % Compute gm/ID at each VGS, then read ratio.
                    id_r = lookup(dev_data,'ID','VGS',x_vec,'L',L,'VDS',vds);
                    gm_r = lookup(dev_data,'GM','VGS',x_vec,'L',L,'VDS',vds);
                    gmid_r = gm_r ./ id_r;
                    gmid_r(isnan(gmid_r)|isinf(gmid_r)|gmid_r<0) = NaN;
                    yd = arrayfun(@(gid) lookup_safe(dev_data, y_key, gid, L, vds), gmid_r);
                    if strcmpi(y_key,'GM_CGG'), yd = yd/(2*pi*1e9); end
                otherwise
                    error('Y key "%s" not supported for X=VGS', y_key);
            end
    end

    yd = yd(:)';
    yd(isnan(yd)|isinf(yd)) = NaN;
end

% =========================================================================
%  HELPER ? lookup_safe  (NaN on out-of-range gm/ID)
% =========================================================================
function v = lookup_safe(dev_data, field, gid, L, vds)
    try
        v = lookup(dev_data, field, 'GM_ID', gid, 'L', L, 'VDS', vds);
    catch
        v = NaN;
    end
    if isempty(v), v = NaN; end
end

% =========================================================================
%  ARBITRARY X/Y DIALOG
%
%  LEFT  : Y-variable listbox  (multi-select; Add -> Left or Right Y)
%  RIGHT : X-variable listbox  (single select: GMID | VGS | VDS)
%  BOTTOM: L, VDS inputs + Plot / Cancel
%
%  Returns:
%    sel_y_keys = {left_cell_array, right_cell_array}
%    sel_x_key  = 'GMID' | 'VGS' | 'VDS'
%    cust_L, cust_vds, ok
% =========================================================================
function [sel_y_keys, sel_x_key, cust_L, cust_vds, ok] = ...
         arbitrary_xy_dialog(CLR, default_vds)
% =========================================================================
%  BUTTON-BASED custom plot dialog
%
%  Layout (960 x 660 px):
%  ???????????????????????????? Title bar ????????????????????????????????
%  ?  ??? Y VARIABLES (grouped buttons) ???????????  ??? RIGHT PANEL ????
%  ?  ?  [Derived]  gm/gds  fT  ID/W  Cgg/W ?    ?  ?  X AXIS buttons ??
%  ?  ?  [Bias]     VGS  VT  VOV  VDSAT           ?  ?  gm/ID | VGS    ??
%  ?  ?  [SmSig]    gm/W  gmb/W  gds/W  ro/W     ?  ????????????????????
%  ?  ?  [Caps]     Cgg/W  Cgd/W  Cdd/W  Css/W   ?  ?  L  input       ??
%  ?  ?  [Current]  gm/ID  ID/W                   ?  ?  VDS input      ??
%  ?  ??????????????????????????????????????????????  ????????????????????
%  ?  Left Y : [display]  [CLR]                       ?  Plot           ??
%  ?  Right Y: [display]  [CLR]                       ?  Cancel         ??
%  ??????????????????????????????????????????????????????????????????????
%
%  Click once   = assign to Left Y  (button turns BLUE)
%  Click again  = reassign to Right Y (button turns ORANGE)
%  Click again  = deselect (button goes dark)
% =========================================================================

    ok         = false;
    sel_y_keys = {{},{}};
    sel_x_key  = 'GMID';
    cust_L     = [];
    cust_vds   = default_vds;

    % ---- Colours --------------------------------------------------------
    fn      = 'Courier New';
    bg      = [0.08 0.11 0.17];   % window background
    panel   = [0.11 0.14 0.20];   % section header background
    acc     = [0.27 0.73 1.00];   % accent (blue)
    fg      = [0.88 0.90 0.94];   % default text
    yel     = [0.95 0.95 0.55];   % input field text
    org     = [1.00 0.65 0.20];   % right-Y colour

    C_idle  = [0.13 0.17 0.25];   % button default bg
    C_left  = [0.08 0.30 0.55];   % button selected Left Y  (blue)
    C_right = [0.42 0.22 0.05];   % button selected Right Y (orange)
    C_x_on  = [0.08 0.38 0.20];   % X-axis active button (green)
    C_x_off = [0.13 0.17 0.25];   % X-axis inactive

    % ---- Y-variable catalogue  {key, label, section} --------------------
    Y_cat = { ...
        'GM_GDS', 'gm/gds',  'Derived'; ...
        'GM_CGG', 'fT',      'Derived'; ...
        'ID_W',   'ID/W',    'Derived'; ...
        'CGG_W',  'Cgg/W',   'Derived'; ...
        'CGD_W',  'Cgd/W',   'Derived'; ...
        'CDD_W',  'Cdd/W',   'Derived'; ...
        'CSS_W',  'Css/W',   'Derived'; ...
        'VGS',    'VGS',     'Bias'; ...
        'VT',     'VT',      'Bias'; ...
        'VOV',    'VOV',     'Bias'; ...
        'VDSAT',  'VDSAT',   'Bias'; ...
        'GM',     'gm/W',    'Small Signal'; ...
        'GMB',    'gmb/W',   'Small Signal'; ...
        'GDS',    'gds/W',   'Small Signal'; ...
        'RO',     'ro/W',    'Small Signal'; ...
        'CGG',    'Cgg/W',   'Capacitances'; ...
        'CGD',    'Cgd/W',   'Capacitances'; ...
        'CDD',    'Cdd/W',   'Capacitances'; ...
        'CSS',    'Css/W',   'Capacitances'; ...
        'GMID',   'gm/ID',   'Current'; ...
        'ID',     'ID/W',    'Current'; ...
    };
    nY = size(Y_cat,1);

    % ---- Sections in display order, with accent colours -----------------
    sec_order  = {'Derived','Bias','Small Signal','Capacitances','Current'};
    sec_colors = {[0.35 0.65 1.00],[0.40 0.90 0.55], ...
                  [1.00 0.72 0.28],[0.75 0.55 1.00],[0.90 0.90 0.40]};

    % ---- Figure ---------------------------------------------------------
    fw = 960;  fh = 660;
    d = figure('Name','Custom Plot', ...
               'Color',bg, ...
               'Position',[120 80 fw fh], ...
               'NumberTitle','off','MenuBar','none','ToolBar','none', ...
               'Resize','off');

    % ---- Title bar ------------------------------------------------------
    uicontrol(d,'Style','text','Units','normalized', ...
        'Position',[0 0.936 1 0.064], ...
        'String','Custom Plot  ?  Select  Y  and  X  variables', ...
        'FontName',fn,'FontSize',14,'FontWeight','bold', ...
        'BackgroundColor',[0.10 0.18 0.30],'ForegroundColor',acc);

    % =====================================================================
    % LEFT AREA: Y-variable button grid  (x: 0.010..0.640)
    % Each section gets a coloured header stripe then a row of buttons.
    % Buttons are 4 per row, uniform size.
    % =====================================================================
    lx0  = 0.010;   % left edge of button area
    lw   = 0.628;   % total width of button area
    bw   = 0.148;   % individual button width
    bh   = 0.072;   % individual button height
    bgap = 0.007;   % horizontal gap between buttons
    sh   = 0.030;   % section header height
    vgap = 0.006;   % vertical gap after section header / between rows

    % Walk from top downward, computing positions
    cur_y = 0.928;  % normalized, walking downward

    h_ybtn   = gobjects(1, nY);  % handles to Y buttons
    btn_state = zeros(1, nY);    % 0=idle 1=left 2=right

    for si = 1:numel(sec_order)
        sname = sec_order{si};
        rows  = find(strcmp(Y_cat(:,3), sname));
        if isempty(rows), continue; end

        % Section header stripe
        cur_y = cur_y - sh - vgap;
        sa = annotation(d,'rectangle',[lx0, cur_y, lw, sh], ...
            'FaceColor', panel, 'Color','none');
        annotation(d,'textbox',[lx0+0.006, cur_y, lw-0.010, sh], ...
            'String', sprintf('  %s', sname), ...
            'Color', sec_colors{si}, ...
            'FontName', fn, 'FontSize', 9.5, 'FontWeight','bold', ...
            'EdgeColor','none','VerticalAlignment','middle');

        % Buttons ? 4 per row
        n_rows = ceil(numel(rows)/4);
        for ri = 1:n_rows
            cur_y = cur_y - bh - vgap;
            for ci = 1:4
                bi = (ri-1)*4 + ci;
                if bi > numel(rows), break; end
                pi  = rows(bi);
                xp  = lx0 + (ci-1)*(bw+bgap);
                h_ybtn(pi) = uicontrol(d, 'Style','pushbutton', ...
                    'Units','normalized', ...
                    'Position',[xp, cur_y, bw, bh], ...
                    'String',   Y_cat{pi,2}, ...
                    'FontName', fn, 'FontSize', 10.5, 'FontWeight','bold', ...
                    'BackgroundColor', C_idle, ...
                    'ForegroundColor', fg, ...
                    'UserData',  pi, ...
                    'TooltipString', Y_cat{pi,1});
                set(h_ybtn(pi),'Callback',@(s,~) y_btn_click(s));
            end
        end
        cur_y = cur_y - vgap;
    end

    % ---- Y selection click handler --------------------------------------
    function y_btn_click(src)
        pi  = get(src,'UserData');
        st  = btn_state(pi);        % 0->1->2->0
        % Remove from old group first
        if st == 1
            sel_left  = sel_left(~strcmp(sel_left,  Y_cat{pi,1}));
        elseif st == 2
            sel_right = sel_right(~strcmp(sel_right, Y_cat{pi,1}));
        end
        % Advance state
        st = mod(st+1, 3);
        btn_state(pi) = st;
        switch st
            case 0  % idle
                set(src,'BackgroundColor',C_idle,'ForegroundColor',fg);
            case 1  % Left Y
                set(src,'BackgroundColor',C_left,'ForegroundColor',[1 1 1]);
                if ~any(strcmp(sel_left, Y_cat{pi,1}))
                    sel_left{end+1} = Y_cat{pi,1}; %#ok
                end
            case 2  % Right Y
                set(src,'BackgroundColor',C_right,'ForegroundColor',[1 1 1]);
                if ~any(strcmp(sel_right, Y_cat{pi,1}))
                    sel_right{end+1} = Y_cat{pi,1}; %#ok
                end
        end
        refresh_disp();
    end

    % ---- Clear buttons for Left / Right ---------------------------------
    disp_y_bot = cur_y - vgap - 0.050;

    uicontrol(d,'Style','text','Units','normalized', ...
        'Position',[lx0, disp_y_bot+0.032, 0.058, 0.030], ...
        'String','Left Y :', 'FontName',fn,'FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',bg,'ForegroundColor',acc, ...
        'HorizontalAlignment','left');
    h_ldisp = uicontrol(d,'Style','edit','Units','normalized', ...
        'Position',[lx0+0.062, disp_y_bot+0.030, 0.490, 0.034], ...
        'String','(none selected)', ...
        'FontName',fn,'FontSize',9, ...
        'BackgroundColor',[0.04 0.07 0.12],'ForegroundColor',yel,'Enable','inactive');
    uicontrol(d,'Style','pushbutton','Units','normalized', ...
        'Position',[lx0+0.558, disp_y_bot+0.030, 0.065, 0.034], ...
        'String','CLR','FontName',fn,'FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',[0.25 0.10 0.10],'ForegroundColor',[1 0.5 0.5], ...
        'Callback',@(~,~) clr_group(1));

    uicontrol(d,'Style','text','Units','normalized', ...
        'Position',[lx0, disp_y_bot-0.010, 0.058, 0.030], ...
        'String','Right Y:', 'FontName',fn,'FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',bg,'ForegroundColor',org, ...
        'HorizontalAlignment','left');
    h_rdisp = uicontrol(d,'Style','edit','Units','normalized', ...
        'Position',[lx0+0.062, disp_y_bot-0.012, 0.490, 0.034], ...
        'String','(none  ?  single axis)', ...
        'FontName',fn,'FontSize',9, ...
        'BackgroundColor',[0.04 0.07 0.12],'ForegroundColor',org,'Enable','inactive');
    uicontrol(d,'Style','pushbutton','Units','normalized', ...
        'Position',[lx0+0.558, disp_y_bot-0.012, 0.065, 0.034], ...
        'String','CLR','FontName',fn,'FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',[0.25 0.10 0.10],'ForegroundColor',[1 0.5 0.5], ...
        'Callback',@(~,~) clr_group(2));

    function clr_group(g)
        if g == 1
            sel_left = {};
            for qi = 1:nY
                if btn_state(qi)==1
                    btn_state(qi)=0;
                    if ishandle(h_ybtn(qi))
                        set(h_ybtn(qi),'BackgroundColor',C_idle,'ForegroundColor',fg);
                    end
                end
            end
        else
            sel_right = {};
            for qi = 1:nY
                if btn_state(qi)==2
                    btn_state(qi)=0;
                    if ishandle(h_ybtn(qi))
                        set(h_ybtn(qi),'BackgroundColor',C_idle,'ForegroundColor',fg);
                    end
                end
            end
        end
        refresh_disp();
    end

    function refresh_disp()
        if isempty(sel_left)
            set(h_ldisp,'String','(none selected)');
        else
            set(h_ldisp,'String', strjoin(sel_left,'  |  '));
        end
        if isempty(sel_right)
            set(h_rdisp,'String','(none  ?  single axis)');
        else
            set(h_rdisp,'String', strjoin(sel_right,'  |  '));
        end
    end

    % =====================================================================
    % RIGHT PANEL  (x: 0.648..0.990)
    % =====================================================================
    rx   = 0.650;
    rpw  = 0.342;    % right panel width

    % ---- Vertical divider -----------------------------------------------
    annotation(d,'line',[rx-0.012 rx-0.012],[0.010 0.928], ...
        'Color',[0.22 0.30 0.40],'LineWidth',1.2);

    % ---- X AXIS section header ------------------------------------------
    annotation(d,'rectangle',[rx, 0.858, rpw, 0.068], ...
        'FaceColor',[0.10 0.22 0.16],'Color','none');
    annotation(d,'textbox',[rx+0.008, 0.858, rpw-0.012, 0.068], ...
        'String','  X  AXIS', ...
        'Color',[0.45 0.92 0.60], ...
        'FontName',fn,'FontSize',11,'FontWeight','bold', ...
        'EdgeColor','none','VerticalAlignment','middle');

    % ---- Two large X-axis buttons ---------------------------------------
    xbh  = 0.092;   % x-button height
    xbw  = (rpw - 0.012) / 2;

    h_xg = uicontrol(d,'Style','pushbutton','Units','normalized', ...
        'Position',[rx,          0.754, xbw, xbh], ...
        'String', sprintf('gm / ID'), ...
        'FontName',fn,'FontSize',13,'FontWeight','bold', ...
        'BackgroundColor',C_x_on,'ForegroundColor',[1 1 1], ...
        'UserData','GMID', ...
        'Callback',@(s,~) x_btn_click(s));

    h_xv = uicontrol(d,'Style','pushbutton','Units','normalized', ...
        'Position',[rx+xbw+0.006, 0.754, xbw, xbh], ...
        'String', sprintf('VGS'), ...
        'FontName',fn,'FontSize',13,'FontWeight','bold', ...
        'BackgroundColor',C_x_off,'ForegroundColor',[0.55 0.75 0.55], ...
        'UserData','VGS', ...
        'Callback',@(s,~) x_btn_click(s));

    % Current X state display
    h_xdisp = uicontrol(d,'Style','text','Units','normalized', ...
        'Position',[rx, 0.718, rpw, 0.030], ...
        'String','X = g_m / I_D', ...
        'FontName',fn,'FontSize',9, ...
        'BackgroundColor',bg,'ForegroundColor',[0.45 0.92 0.60], ...
        'HorizontalAlignment','center');

    cur_x_key = 'GMID';

    function x_btn_click(src)
        cur_x_key = get(src,'UserData');
        if strcmp(cur_x_key,'GMID')
            set(h_xg,'BackgroundColor',C_x_on, 'ForegroundColor',[1 1 1]);
            set(h_xv,'BackgroundColor',C_x_off,'ForegroundColor',[0.55 0.75 0.55]);
            set(h_xdisp,'String','X = g_m / I_D');
        else
            set(h_xv,'BackgroundColor',C_x_on, 'ForegroundColor',[1 1 1]);
            set(h_xg,'BackgroundColor',C_x_off,'ForegroundColor',[0.55 0.75 0.55]);
            set(h_xdisp,'String','X = V_{GS}');
        end
    end

    % ---- Divider --------------------------------------------------------
    annotation(d,'line',[rx, rx+rpw],[0.710 0.710], ...
        'Color',[0.22 0.30 0.40],'LineWidth',0.9);

    % ---- L input --------------------------------------------------------
    uicontrol(d,'Style','text','Units','normalized', ...
        'Position',[rx, 0.654, rpw, 0.040], ...
        'String','L  (um)   e.g.  0.5   or   0.1:0.2:0.9', ...
        'FontName',fn,'FontSize',8.5,'FontWeight','bold', ...
        'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left');
    h_L = uicontrol(d,'Style','edit','Units','normalized', ...
        'Position',[rx, 0.595, rpw, 0.055], ...
        'String','0.5','FontName',fn,'FontSize',13, ...
        'BackgroundColor',[0.04 0.07 0.12],'ForegroundColor',yel);

    % ---- VDS input ------------------------------------------------------
    uicontrol(d,'Style','text','Units','normalized', ...
        'Position',[rx, 0.540, rpw, 0.040], ...
        'String','V_DS  (V)', ...
        'FontName',fn,'FontSize',8.5,'FontWeight','bold', ...
        'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left');
    h_vds = uicontrol(d,'Style','edit','Units','normalized', ...
        'Position',[rx, 0.480, rpw, 0.055], ...
        'String',sprintf('%.2f', default_vds),'FontName',fn,'FontSize',13, ...
        'BackgroundColor',[0.04 0.07 0.12],'ForegroundColor',yel);

    % ---- Divider --------------------------------------------------------
    annotation(d,'line',[rx, rx+rpw],[0.468 0.468], ...
        'Color',[0.22 0.30 0.40],'LineWidth',0.9);

    % ---- Plot / Cancel buttons ------------------------------------------
    uicontrol(d,'Style','pushbutton','Units','normalized', ...
        'Position',[rx, 0.350, rpw, 0.105], ...
        'String','Plot','FontName',fn,'FontSize',17,'FontWeight','bold', ...
        'BackgroundColor',[0.10 0.36 0.58],'ForegroundColor',[1 1 1], ...
        'Callback',@do_ok);

    uicontrol(d,'Style','pushbutton','Units','normalized', ...
        'Position',[rx, 0.230, rpw, 0.095], ...
        'String','Cancel','FontName',fn,'FontSize',13, ...
        'BackgroundColor',[0.32 0.10 0.10],'ForegroundColor',[1 1 1], ...
        'Callback',@(~,~) delete(d));

    % ---- Legend / instruction card -------------------------------------
    annotation(d,'rectangle',[rx, 0.010, rpw, 0.205], ...
        'FaceColor',[0.07 0.10 0.16],'Color',[0.20 0.28 0.38]);
    annotation(d,'textbox',[rx+0.006, 0.012, rpw-0.010, 0.200], ...
        'String', {' HOW TO USE:', ...
                   ' Click Y button once  =  Left Y  (blue)', ...
                   ' Click same button again  =  Right Y  (orange)', ...
                   ' Click again  =  deselect', ...
                   ' ', ...
                   ' Select X axis with the two buttons above.', ...
                   ' ', ...
                   ' Left Y   uses the LEFT y-axis.', ...
                   ' Right Y  uses the RIGHT y-axis (orange).'}, ...
        'Color',[0.55 0.65 0.78], ...
        'FontName',fn,'FontSize',8.5, ...
        'EdgeColor','none','VerticalAlignment','top');

    % ---- State ----------------------------------------------------------
    sel_left  = {};
    sel_right = {};

    res.ok = false;
    setappdata(d,'res',res);

    function do_ok(~,~)
        if isempty(sel_left)
            errordlg('Select at least one Left Y variable (click a button once).', ...
                     'Input Error');
            return;
        end

        raw_L = strtrim(get(h_L,'String'));
        if contains(raw_L,':') || contains(raw_L,'linspace')
            r_L = str2num(raw_L); %#ok<ST2NM>
        else
            r_L = str2double(raw_L);
            if isnan(r_L), r_L = []; end
        end
        r_vds = str2double(get(h_vds,'String'));

        if isempty(r_L) || any(isnan(r_L))
            errordlg('Enter a valid L.  e.g.  0.5  or  0.1:0.2:0.9','Input Error');
            return;
        end
        if isnan(r_vds)
            errordlg('Enter a valid VDS value.','Input Error');
            return;
        end

        r.sel_y_keys = {sel_left, sel_right};
        r.sel_x_key  = cur_x_key;
        r.cust_L     = r_L;
        r.cust_vds   = r_vds;
        r.ok         = true;
        setappdata(d,'res',r);
        uiresume(d);
    end

    uiwait(d);

    if ishandle(d)
        res        = getappdata(d,'res');
        sel_y_keys = res.sel_y_keys;
        sel_x_key  = res.sel_x_key;
        cust_L     = res.cust_L;
        cust_vds   = res.cust_vds;
        ok         = res.ok;
        delete(d);
    end
end


% =========================================================================
%  PROFILER WINDOW
% =========================================================================
function show_profiler_window(State, rep, ...
        req_gmid, req_id, req_L, req_vds, req_vsb, ...
        req_W, req_vgs, req_vth, req_vov, req_vdsat, ...
        req_fT, gain, req_gm, req_gds, ...
        req_cgg, req_cgd, req_cdd, ...
        gmv, fTv, Avv, idwv, FoMv)

    CLR   = State.CLR;
    isN   = strcmp(State.current_dev,'nch');
    dname = 'NMOS'; if ~isN, dname='PMOS'; end
    lc    = CLR.nmos_lines{1}; if ~isN, lc=CLR.pmos_lines{1}; end
    lc2   = CLR.nmos_lines{3}; if ~isN, lc2=CLR.pmos_lines{3}; end

    pf = figure( ...
        'Name',    sprintf('Transistor Profiler  [%s]   L = %s   VDS = %s   VSB = %s', ...
                           dname, eng(req_L*1e-6,'m'), eng(req_vds,'V'), eng(req_vsb,'V')), ...
        'Color',   CLR.bg, ...
        'Position',[40 40 1540 720], ...
        'NumberTitle','off');
    set(pf,'WindowKeyPressFcn',@(f,e) cadence_shortcuts(f,e));
    setappdata(pf,'State',State);

    uicontrol(pf,'Style','edit','Max',40,'Min',1, ...
        'Units','normalized','Position',[0.005 0.005 0.240 0.990], ...
        'String',        strsplit(rep, newline), ...
        'FontName',      'Courier New', ...
        'FontSize',      12.5, ...
        'HorizontalAlignment','left', ...
        'BackgroundColor', CLR.panel, ...
        'ForegroundColor', [0.75 0.95 0.65], ...
        'Enable',        'inactive');

    px0 = 0.250; pw = 0.260; ph = 0.430;
    py_top = 0.535; py_bot = 0.040; gap = 0.015;

    ppos = { [px0,          py_top, pw, ph]; ...
             [px0+pw+gap,   py_top, pw, ph]; ...
             [px0,          py_bot, pw, ph]; ...
             [px0+pw+gap,   py_bot, pw, ph] };

    y_data   = {fTv/1e9,       Avv,              idwv,            FoMv};
    y_labels = {'f_T  (GHz)',  'Gain  (V/V)',    'I_D/W  (A/um)', 'FoM  (GHz/V)'};
    titls    = {'Transit Frequency  f_T', ...
                'Intrinsic Gain  g_m / g_{ds}', ...
                'Current Density  I_D/W', ...
                'Speed-Power FoM'};
    use_log  = [false false true false];

    ax_all = gobjects(1,4);
    for k = 1:4
        ax = axes('Parent',pf, 'Units','normalized', ...
                  'OuterPosition', ppos{k});
        style_axes_pro(ax, CLR);
        hold(ax,'on');

        plot(ax, gmv, y_data{k}, 'Color',lc2, 'LineWidth',3.5, 'Tag','data_curve');
        plot(ax, gmv, y_data{k}, 'Color',lc,  'LineWidth',2.0, 'Tag','data_curve');

        if use_log(k), set(ax,'YScale','log'); end

        xline(ax, req_gmid, 'Color',CLR.marker_v, 'LineWidth',1.4, ...
              'Label', sprintf(' %.1f ', req_gmid));

        yi = interp1(gmv, y_data{k}, req_gmid,'linear');
        plot(ax, req_gmid, yi, 'o', ...
             'Color',CLR.op_dot,'MarkerFaceColor',CLR.op_dot, ...
             'MarkerEdgeColor',[1 1 1],'MarkerSize',9,'LineWidth',1.2);

        yl_rng = ylim(ax);
        va = 'bottom'; if yi < mean(yl_rng), va = 'top'; end
        if use_log(k), fmt = '  %.3g'; else, fmt = '  %.4g'; end
        text(ax, req_gmid, yi, sprintf(fmt, yi), ...
             'Color',CLR.op_dot,'FontSize',9.5,'FontWeight','bold', ...
             'VerticalAlignment',va,'BackgroundColor',CLR.bg,'Margin',1);

        if k >= 3
            xlabel(ax,'g_m/I_D  (1/V)','Color',CLR.ax_fg,'FontSize',10,'FontWeight','normal');
        else
            set(ax,'XTickLabel',[]);
        end
        ylabel(ax, y_labels{k}, 'Color',CLR.ax_fg,'FontSize',10);
        title(ax,  titls{k},    'Color',CLR.ax_fg,'FontSize',10.5,'FontWeight','bold');

        ax_all(k) = ax;
    end
    linkaxes(ax_all,'x');

    % Parameter card
    card_x = px0 + 2*(pw+gap) + 0.010;
    card_w = 1.0 - card_x - 0.004;

    annotation(pf,'rectangle',[card_x 0.005 card_w 0.990], ...
        'Color','none','FaceColor',[0.08 0.11 0.17],'FaceAlpha',1.0);
    annotation(pf,'rectangle',[card_x 0.895 card_w 0.100], ...
        'Color','none','FaceColor',[0.12 0.22 0.35],'FaceAlpha',1.0);
    annotation(pf,'textbox',[card_x 0.895 card_w 0.100], ...
        'String', sprintf('[%s]   L = %s', dname, eng(req_L*1e-6,'m')), ...
        'Color',CLR.accent,'FontName','Courier New','FontSize',12.0,'FontWeight','bold', ...
        'EdgeColor','none','Interpreter','none', ...
        'HorizontalAlignment','center','VerticalAlignment','middle');

    C_lbl  = CLR.ax_fg;
    C_val  = [0.95 0.95 0.60];
    C_sep  = [0.22 0.30 0.40];
    C_head = [0.55 0.75 0.95];

    param_rows = { ...
        'GEOMETRY',         '',                                          'head'; ...
        'W',                eng(req_W*1e-6,'m'),                         C_val; ...
        'ID',               eng(req_id,'A'),                             C_val; ...
        '',                 '',                                          'sep';  ...
        'BIAS',             '',                                          'head'; ...
        'VGS',              eng(req_vgs,'V'),                            C_val; ...
        'VT',               eng(req_vth,'V'),                            C_val; ...
        'VOV',              eng(req_vov,'V'),                            C_val; ...
        'VDSAT',            eng(req_vdsat,'V'),                          C_val; ...
        'VDS',              eng(req_vds,'V'),                            C_val; ...
        'VSB',              eng(req_vsb,'V'),                            C_val; ...
        '',                 '',                                          'sep';  ...
        'SMALL SIGNAL',     '',                                          'head'; ...
        'gm',               eng(req_gm,'S'),                             C_val; ...
        'gds',              eng(req_gds,'S'),                            C_val; ...
        'Gain',             sprintf('%.3f V/V',  gain),                  C_val; ...
        'Gain dB',          sprintf('%.1f dB',   20*log10(abs(gain))),   C_val; ...
        'fT',               eng(req_fT,'Hz'),                            C_val; ...
        '',                 '',                                          'sep';  ...
        'CAPACITANCES',     '',                                          'head'; ...
        'Cgg',              eng(req_cgg,'F'),                            C_val; ...
        'Cgd',              eng(req_cgd,'F'),                            C_val; ...
        'Cdd',              eng(req_cdd,'F'),                            C_val; ...
        'Cgd/Cgg',          sprintf('%.4f', req_cgd/req_cgg),            C_val; ...
    };

    n_rows  = size(param_rows,1);
    row_h   = 0.885 / n_rows;
    y_start = 0.890;

    for r = 1:n_rows
        lbl  = param_rows{r,1};
        val  = param_rows{r,2};
        kind = param_rows{r,3};
        y_bot = y_start - r*row_h;

        if strcmp(kind,'sep')
            annotation(pf,'line', ...
                [card_x+0.002, card_x+card_w-0.002], ...
                [y_bot+row_h*0.5, y_bot+row_h*0.5], ...
                'Color',C_sep,'LineWidth',0.8);
            continue;
        end
        if strcmp(kind,'head')
            annotation(pf,'rectangle', ...
                [card_x+0.001, y_bot+row_h*0.08, card_w-0.002, row_h*0.84], ...
                'Color','none','FaceColor',[0.10 0.18 0.28],'FaceAlpha',0.9);
            annotation(pf,'textbox', ...
                [card_x+0.006, y_bot, card_w-0.008, row_h], ...
                'String',lbl,'Color',C_head,'FontName','Courier New', ...
                'FontSize',10.5,'FontWeight','bold','EdgeColor','none', ...
                'Interpreter','none','VerticalAlignment','middle','HorizontalAlignment','left');
            continue;
        end
        annotation(pf,'textbox', ...
            [card_x+0.006, y_bot, card_w*0.46, row_h], ...
            'String',lbl,'Color',C_lbl,'FontName','Courier New', ...
            'FontSize',11.0,'EdgeColor','none','Interpreter','none', ...
            'VerticalAlignment','middle','HorizontalAlignment','left');
        annotation(pf,'textbox', ...
            [card_x+card_w*0.48, y_bot, card_w*0.50, row_h], ...
            'String',val,'Color',kind,'FontName','Courier New', ...
            'FontSize',11.0,'FontWeight','bold','EdgeColor','none', ...
            'Interpreter','none','VerticalAlignment','middle','HorizontalAlignment','right');
    end
end

% =========================================================================
%  SIZING WINDOW
% =========================================================================
function show_sizing_window(State, rep, ...
        req_gmid, req_id, req_L, req_vds, req_W, req_vgs, ...
        req_gm, req_fT, req_gain, ...
        dense_L, gain_L, ...
        gmv, fTv, Avv, idwv, FoMv, CLR)

    isN   = strcmp(State.current_dev,'nch');
    dname = 'NMOS'; if ~isN, dname='PMOS'; end
    lc    = CLR.nmos_lines{1}; if ~isN, lc=CLR.pmos_lines{1}; end
    lc2   = CLR.nmos_lines{3}; if ~isN, lc2=CLR.pmos_lines{3}; end

    sf = figure( ...
        'Name',    sprintf('Exact Sizing  [%s]   L=%s   gm/ID=%.1f   VDS=%s', ...
                           dname, eng(req_L*1e-6,'m'), req_gmid, eng(req_vds,'V')), ...
        'Color',   CLR.bg, ...
        'Position',[40 40 1540 700], ...
        'NumberTitle','off');
    set(sf,'WindowKeyPressFcn',@(f,e) cadence_shortcuts(f,e));
    setappdata(sf,'State',State);

    uicontrol(sf,'Style','edit','Max',40,'Min',1, ...
        'Units','normalized','Position',[0.005 0.005 0.235 0.990], ...
        'String',        strsplit(rep, newline), ...
        'FontName',      'Courier New', ...
        'FontSize',      12.5, ...
        'HorizontalAlignment','left', ...
        'BackgroundColor', CLR.panel, ...
        'ForegroundColor', [0.75 0.95 0.65], ...
        'Enable',        'inactive');

    px0 = 0.250; pw = 0.255; ph = 0.420;
    py_top = 0.540; py_bot = 0.045; gap = 0.015;

    ax1 = axes('Parent',sf,'Units','normalized', ...
               'OuterPosition',[px0, py_top, pw, ph]);
    style_axes_pro(ax1, CLR);  hold(ax1,'on');

    plot(ax1, dense_L, gain_L, 'Color',lc2,'LineWidth',3.5,'Tag','data_curve');
    plot(ax1, dense_L, gain_L, 'Color',lc, 'LineWidth',2.0,'Tag','data_curve');

    yline(ax1, req_gain, 'Color',CLR.marker_h,'LineWidth',1.4, ...
          'Label',sprintf(' %.1f V/V ',req_gain));
    plot(ax1, req_L, req_gain, 'o', ...
         'Color',CLR.op_dot,'MarkerFaceColor',CLR.op_dot, ...
         'MarkerEdgeColor',[1 1 1],'MarkerSize',10,'LineWidth',1.2);
    xline(ax1, req_L,'Color',CLR.marker_v,'LineWidth',1.3, ...
          'Label',sprintf(' %s ',eng(req_L*1e-6,'m')));
    text(ax1, req_L, req_gain, sprintf('  %s', eng(req_L*1e-6,'m')), ...
         'Color',CLR.op_dot,'FontSize',9.5,'FontWeight','bold', ...
         'VerticalAlignment','bottom','BackgroundColor',CLR.bg,'Margin',1);

    xlabel(ax1,'L  (um)','Color',CLR.ax_fg,'FontSize',10);
    ylabel(ax1,'Gain  (V/V)','Color',CLR.ax_fg,'FontSize',10);
    title(ax1,'Intrinsic Gain  A_v  vs  L','Color',CLR.ax_fg, ...
          'FontSize',10.5,'FontWeight','bold');

    ppos2 = {[px0+pw+gap, py_top, pw, ph]; ...
             [px0,        py_bot, pw, ph]; ...
             [px0+pw+gap, py_bot, pw, ph]};
    y_data2  = {fTv/1e9, idwv, FoMv};
    y_labels2= {'f_T  (GHz)','I_D/W  (A/um)','FoM  (GHz/V)'};
    titls2   = {'Transit Frequency  f_T','Current Density  I_D/W','Speed-Power FoM'};
    use_log2 = [false true false];
    yi_op2   = [interp1(gmv,fTv/1e9,req_gmid,'linear'), ...
                interp1(gmv,idwv,   req_gmid,'linear'), ...
                interp1(gmv,FoMv,   req_gmid,'linear')];

    ax_gmid = gobjects(1,3);
    for k = 1:3
        ax = axes('Parent',sf,'Units','normalized','OuterPosition',ppos2{k});
        style_axes_pro(ax, CLR);  hold(ax,'on');

        plot(ax,gmv,y_data2{k},'Color',lc2,'LineWidth',3.5,'Tag','data_curve');
        plot(ax,gmv,y_data2{k},'Color',lc, 'LineWidth',2.0,'Tag','data_curve');
        if use_log2(k), set(ax,'YScale','log'); end

        xline(ax,req_gmid,'Color',CLR.marker_v,'LineWidth',1.3, ...
              'Label',sprintf(' %.1f ',req_gmid));
        yi = yi_op2(k);
        plot(ax,req_gmid,yi,'o','Color',CLR.op_dot,'MarkerFaceColor',CLR.op_dot, ...
             'MarkerEdgeColor',[1 1 1],'MarkerSize',9,'LineWidth',1.2);
        yl_rng = ylim(ax);
        va = 'bottom'; if yi < mean(yl_rng), va='top'; end
        text(ax,req_gmid,yi,sprintf('  %.4g',yi), ...
             'Color',CLR.op_dot,'FontSize',9.5,'FontWeight','bold', ...
             'VerticalAlignment',va,'BackgroundColor',CLR.bg,'Margin',1);

        if k >= 2
            xlabel(ax,'g_m/I_D  (1/V)','Color',CLR.ax_fg,'FontSize',10);
        else
            set(ax,'XTickLabel',[]);
        end
        ylabel(ax,y_labels2{k},'Color',CLR.ax_fg,'FontSize',10);
        title(ax,titls2{k},'Color',CLR.ax_fg,'FontSize',10.5,'FontWeight','bold');
        ax_gmid(k) = ax;
    end
    linkaxes(ax_gmid,'x');

    % Result card
    card_x = px0 + 2*(pw+gap) + 0.010;
    card_w = 1.0 - card_x - 0.004;

    annotation(sf,'rectangle',[card_x 0.005 card_w 0.990], ...
        'Color','none','FaceColor',[0.08 0.11 0.17],'FaceAlpha',1.0);
    annotation(sf,'rectangle',[card_x 0.895 card_w 0.100], ...
        'Color','none','FaceColor',[0.12 0.22 0.35],'FaceAlpha',1.0);
    annotation(sf,'textbox',[card_x 0.895 card_w 0.100], ...
        'String', sprintf('[%s]   gm/ID = %.1f', dname, req_gmid), ...
        'Color',CLR.accent,'FontName','Courier New','FontSize',11.5,'FontWeight','bold', ...
        'EdgeColor','none','Interpreter','none', ...
        'HorizontalAlignment','center','VerticalAlignment','middle');

    C_lbl  = CLR.ax_fg;
    C_val  = [0.95 0.95 0.60];
    C_head = [0.55 0.75 0.95];
    C_sep  = [0.22 0.30 0.40];

    card_rows = { ...
        'RESULT',      '',                              'head'; ...
        'L',           eng(req_L*1e-6,'m'),             C_val; ...
        'W',           eng(req_W*1e-6,'m'),             C_val; ...
        '',            '',                              'sep';  ...
        'BIAS',        '',                              'head'; ...
        'ID',          eng(req_id,'A'),                 C_val; ...
        'VGS',         eng(req_vgs,'V'),                C_val; ...
        'VDS',         eng(req_vds,'V'),                C_val; ...
        '',            '',                              'sep';  ...
        'PERFORMANCE', '',                              'head'; ...
        'gm',          eng(req_gm,'S'),                 C_val; ...
        'Gain',        sprintf('%.2f V/V',req_gain),    C_val; ...
        'Gain dB',     sprintf('%.1f dB',20*log10(req_gain)), C_val; ...
        'fT',          eng(req_fT,'Hz'),                C_val; ...
        '',            '',                              'sep';  ...
        'OP. POINT',   '',                              'head'; ...
        'gm/ID',       sprintf('%.1f V^-1',req_gmid),  C_val; ...
        'FoM',         sprintf('%.2f GHz/V', req_fT*req_gmid/1e9), C_val; ...
    };

    n_rows  = size(card_rows,1);
    row_h   = 0.885 / n_rows;
    y_start = 0.890;

    for r = 1:n_rows
        lbl  = card_rows{r,1};
        val  = card_rows{r,2};
        kind = card_rows{r,3};
        y_bot = y_start - r*row_h;

        if strcmp(kind,'sep')
            annotation(sf,'line', ...
                [card_x+0.002, card_x+card_w-0.002], ...
                [y_bot+row_h*0.5, y_bot+row_h*0.5], ...
                'Color',C_sep,'LineWidth',0.8);
            continue;
        end
        if strcmp(kind,'head')
            annotation(sf,'rectangle', ...
                [card_x+0.001, y_bot+row_h*0.08, card_w-0.002, row_h*0.84], ...
                'Color','none','FaceColor',[0.10 0.18 0.28],'FaceAlpha',0.9);
            annotation(sf,'textbox', ...
                [card_x+0.006, y_bot, card_w-0.008, row_h], ...
                'String',lbl,'Color',C_head,'FontName','Courier New', ...
                'FontSize',10.5,'FontWeight','bold','EdgeColor','none', ...
                'Interpreter','none','VerticalAlignment','middle','HorizontalAlignment','left');
            continue;
        end
        annotation(sf,'textbox', ...
            [card_x+0.006, y_bot, card_w*0.46, row_h], ...
            'String',lbl,'Color',C_lbl,'FontName','Courier New', ...
            'FontSize',11.0,'EdgeColor','none','Interpreter','none', ...
            'VerticalAlignment','middle','HorizontalAlignment','left');
        annotation(sf,'textbox', ...
            [card_x+card_w*0.48, y_bot, card_w*0.50, row_h], ...
            'String',val,'Color',kind,'FontName','Courier New', ...
            'FontSize',11.0,'FontWeight','bold','EdgeColor','none', ...
            'Interpreter','none','VerticalAlignment','middle','HorizontalAlignment','right');
    end
end

% =========================================================================
%  HELPER ? style_axes_pro
% =========================================================================
function style_axes_pro(ax, CLR)
    set(ax, ...
        'Color',          CLR.panel, ...
        'XColor',         CLR.ax_fg, ...
        'YColor',         CLR.ax_fg, ...
        'GridColor',      CLR.grid, ...
        'MinorGridColor', CLR.grid, ...
        'GridAlpha',      0.45, ...
        'MinorGridAlpha', 0.20, ...
        'TickDir',        'out', ...
        'TickLength',     [0.012 0.025], ...
        'FontSize',       9.5, ...
        'FontName',       'Helvetica', ...
        'LineWidth',      0.9, ...
        'Box',            'off', ...
        'XMinorTick',     'on', ...
        'YMinorTick',     'on');
    grid(ax,'on');
end

% =========================================================================
%  HELPER ? build_profiler_report
% =========================================================================
function rep = build_profiler_report(dev, ...
        gmid, id, L, vds, vsb, ...
        W, vgs, vth, vov, vdsat, ...
        gm, gds, gain, fT, cgg, cgd, cdd)
    d   = upper(dev);
    sep = [repmat('=',1,58) newline];
    rep = [ sep ...
        sprintf(' TRANSISTOR PROFILE  [%s]\n', d) ...
        sprintf(' I_D=%s  L=%s  gm/ID=%.1f  VDS=%s  VSB=%s\n', ...
            eng(id,'A'), eng(L*1e-6,'m'), gmid, eng(vds,'V'), eng(vsb,'V')) ...
        sep ...
        sprintf(' %-22s: %8s\n', 'Width  (W)',     eng(W*1e-6,'m')) ...
        sprintf(' %-22s: %8s\n', 'V_GS',           eng(vgs,'V')) ...
        sprintf(' %-22s: %8s\n', 'V_TH',           eng(vth,'V')) ...
        sprintf(' %-22s: %8s\n', 'V_OV = VGS-VTH', eng(vov,'V')) ...
        sprintf(' %-22s: %8s\n', 'V_DSAT',         eng(vdsat,'V')) ...
        sprintf(' %-22s: %8s\n', 'g_m',            eng(gm,'S')) ...
        sprintf(' %-22s: %8s\n', 'g_ds',           eng(gds,'S')) ...
        sprintf(' %-22s: %8.3f V/V  (%.1f dB)\n', 'Intrinsic Gain A_v', gain, 20*log10(abs(gain))) ...
        sprintf(' %-22s: %8s\n', 'f_T',            eng(fT,'Hz')) ...
        sprintf(' %-22s: %8s\n', 'C_gg',           eng(cgg,'F')) ...
        sprintf(' %-22s: %8s\n', 'C_gd',           eng(cgd,'F')) ...
        sprintf(' %-22s: %8s\n', 'C_dd',           eng(cdd,'F')) ...
        sprintf(' %-22s: %8.3f\n', 'C_gd/C_gg ratio', cgd/cgg) ...
        sep ];
end

% =========================================================================
%  HELPER ? build_report
% =========================================================================
function rep = build_report(title_str, subtitle, dev, hdr, rows)
    sep = [repmat('=',1,65) newline];
    rep = [sep sprintf('  %s  [%s]\n',title_str,dev) ...
           sprintf('  %s\n',subtitle) sep];
    if ~isempty(hdr)
        rep = [rep sprintf(' %s\n',hdr) repmat('-',1,65) newline];
    end
    for k=1:numel(rows)
        rep = [rep rows{k} newline];
    end
    rep = [rep sep];
end

% =========================================================================
%  HELPER ? show_text_window
% =========================================================================
function show_text_window(rep, title_str, CLR)
    n_lines = numel(strsplit(rep, newline));
    win_h   = min(max(n_lines*22+60, 340), 720);
    rf = figure('Name',title_str,'Color',CLR.bg, ...
                'Position',[200 180 760 win_h], ...
                'MenuBar','none','ToolBar','none', ...
                'NumberTitle','off','Resize','on');
    uicontrol(rf,'Style','edit','Max',40,'Min',1, ...
        'Units','normalized','Position',[0.015 0.015 0.970 0.970], ...
        'String',             strsplit(rep, newline), ...
        'FontName',           'Courier New', ...
        'FontSize',           12.5, ...
        'HorizontalAlignment','left', ...
        'BackgroundColor',    CLR.panel, ...
        'ForegroundColor',    [0.82 0.95 0.75], ...
        'Enable',             'inactive');
end

% =========================================================================
%  HELPER ? eng   Engineering notation formatter
% =========================================================================
function s = eng(x, unit)
    if nargin < 2, unit = ''; end
    if isnan(x) || isinf(x)
        s = [num2str(x) ' ' unit]; return;
    end
    prefixes = {'T','G','M','k','','m','u','n','p','f','a'};
    exps     = [12,  9,  6,  3,  0, -3, -6, -9,-12,-15,-18];
    ax = abs(x);
    if ax == 0
        s = ['0 ' unit]; return;
    end
    idx = find(ax >= 10.^exps, 1, 'first');
    if isempty(idx), idx = numel(exps); end
    val = x / 10^exps(idx);
    pre = prefixes{idx};
    if abs(val) >= 100
        s = sprintf('%.1f %s%s', val, pre, unit);
    elseif abs(val) >= 10
        s = sprintf('%.2f %s%s', val, pre, unit);
    else
        s = sprintf('%.3f %s%s', val, pre, unit);
    end
    s = strtrim(s);
end

% =========================================================================
%  HELPER ? parse_eng   Engineering-notation string -> SI value
% =========================================================================
function val = parse_eng(s)
    s = strtrim(s);
    if isempty(s), val = NaN; return; end
    suffixes = {'T','G','M','k','m','u','n','p','f','a'};
    exps     = [ 12,  9,  6,  3, -3, -6, -9,-12,-15,-18];
    val = str2double(s);
    if ~isnan(val), return; end
    pat = '^([+-]?[0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)\s*([TGMkmunpfa])';
    tok = regexp(s, pat, 'tokens', 'once');
    if isempty(tok)
        pat2 = '^([+-]?[0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)\s*[Kk]';
        tok2 = regexp(s, pat2, 'tokens', 'once');
        if isempty(tok2), val = NaN; return; end
        val = str2double(tok2{1}) * 1e3;
        return;
    end
    num = str2double(tok{1});
    suf = tok{2};
    idx = strcmp(suffixes, suf);
    if ~any(idx), val = NaN; return; end
    val = num * 10^exps(idx);
end

% =========================================================================
%  HELPER ? style_axes  (dark theme)
% =========================================================================
function style_axes(ax, CLR)
    set(ax, ...
        'Color',          CLR.panel, ...
        'XColor',         CLR.ax_fg, ...
        'YColor',         CLR.ax_fg, ...
        'GridColor',      CLR.grid, ...
        'MinorGridColor', CLR.grid, ...
        'GridAlpha',      0.5, ...
        'TickDir',        'out', ...
        'FontSize',       9.5, ...
        'FontName',       'Helvetica', ...
        'LineWidth',      0.8, ...
        'Box',            'off');
    grid(ax,'on');
end

% =========================================================================
%  DRAG ? Vertical marker
% =========================================================================
function startDragV(~, fig, cid)
    set(fig,'WindowButtonMotionFcn',{@dragV,fig,cid},'WindowButtonUpFcn',@stopDrag);
end
function dragV(~,~,fig,cid)
    ax=gca; nx=get(ax,'CurrentPoint'); nx=nx(1,1);
    xls = findobj(fig,'Tag',['v_cursor_' cid]);
    for kx=1:numel(xls)
        xls(kx).Value=nx;
        xls(kx).Label=sprintf('  gm/ID=%.2f  ',nx);
    end
    updateVI(fig,cid,nx);
end
function updateVI(fig,cid,nx)
    allax = findobj(fig,'Type','axes');
    marks = findobj(fig,'Tag',['v_mark_' cid]);
    texts = findobj(fig,'Tag',['v_text_' cid]);
    idx=1;
    for i=1:numel(allax)
        for dl=findobj(allax(i),'Tag','data_curve')'
            xd=dl.XData; yd=dl.YData;
            if nx>=min(xd)&&nx<=max(xd)
                [xu,iu]=unique(xd); yu=yd(iu);
                yi=interp1(xu,yu,nx,'linear');
                marks(idx).XData=nx; marks(idx).YData=yi;
                texts(idx).Position=[nx yi 0];
                texts(idx).String=sprintf(' %.3g',yi);
            else
                marks(idx).XData=NaN; marks(idx).YData=NaN; texts(idx).String='';
            end
            idx=idx+1;
        end
    end
end

% =========================================================================
%  DRAG ? Horizontal marker
% =========================================================================
function startDragH(~,fig,cid)
    set(fig,'WindowButtonMotionFcn',{@dragH,fig,cid},'WindowButtonUpFcn',@stopDrag);
end
function dragH(~,~,fig,cid)
    ax=gca; ny=get(ax,'CurrentPoint'); ny=ny(1,2);
    yls = findobj(ax,'Tag',['h_cursor_' cid]);
    for ky=1:numel(yls)
        yls(ky).Value=ny;
        yls(ky).Label=sprintf('  y=%.3g  ',ny);
    end
    updateHI(ax,cid,ny);
end
function updateHI(ax,cid,ny)
    marks=findobj(ax,'Tag',['h_mark_' cid]);
    texts=findobj(ax,'Tag',['h_text_' cid]);
    dls=findobj(ax,'Tag','data_curve');
    for j=1:numel(dls)
        xd=dls(j).XData; yd=dls(j).YData;
        [ys,si]=sort(yd); xs=xd(si);
        [yu,iu]=unique(ys); xu=xs(iu);
        if ny>=min(yu)&&ny<=max(yu)
            xi=interp1(yu,xu,ny,'linear');
            marks(j).XData=xi; marks(j).YData=ny;
            texts(j).Position=[xi ny 0];
            texts(j).String=sprintf(' gm/ID=%.2f',xi);
        else
            marks(j).XData=NaN; marks(j).YData=NaN; texts(j).String='';
        end
    end
end
function stopDrag(fig,~)
    set(fig,'WindowButtonMotionFcn','','WindowButtonUpFcn','');
end
