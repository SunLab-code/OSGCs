function results = fBatchFitOrientationTuning_OBI_PP(inputFile, outputFile)
% fBatchFitOrientationTuning_OBI_PP
%
% Batch fit orientation tuning curves from an Excel file.
%
% Input xlsx format:
%   Row 1     : cell names
%   Row 2-7   : x angles, in degrees
%   Row 8-13  : response R
%   Each col  : one cell
%
% Model:
%   R_norm(x) = exp(k*cos(2*(x-mu))) / exp(k)
%
% Notes:
%   1. Rmax is fixed as max(R), not fitted.
%   2. R_norm = R / Rmax is used for fitting and plotting.
%   3. mu is fitted in [0, pi], because orientation tuning is 180-degree periodic.
%
% Output:
%   Figure 1: each cell's normalized tuning curve in separate polar subplot
%   Figure 2: all cells' mu-OBI bidirectional vectors
%   Figure 3: all cells' x_pref-OBI bidirectional vectors
%   Figure 4: x_pref clustered as horizontal vs vertical
%   Figure 5: x_pref clustered onto two unsupervised orthogonal axes
%   Figure 6: x_pref clustered into two unsupervised groups, not forced orthogonal
%   PP_Cells: one JPG polar plot for each cell, using 360-degree duplicated responses
%   output.xlsx: fitting and clustering results
%
% Usage:
%   results = fBatchFitOrientationTuning_OBI_PP('input.xlsx', 'output.xlsx');

    if nargin < 2
        outputFile = 'output.xlsx';
    end

    %% Read Excel file
    raw = readcell(inputFile);

    if size(raw, 1) < 13
        error('Input file must contain at least 13 rows.');
    end

    nCells = size(raw, 2);

    %% Directory for individual cell polar plots
    % Each cell will be exported as a JPG file.
    % The directory is created in the same folder as outputFile.
    [outputFolder, ~, ~] = fileparts(outputFile);

    if isempty(outputFolder)
        outputFolder = pwd;
    end

    ppDir = fullfile(outputFolder, 'PP_Cells');

    if ~exist(ppDir, 'dir')
        mkdir(ppDir);
    end

    %% Colors for individual cells
    cellColors = lines(nCells);

    %% Output variables
    cellNames = strings(1, nCells);

    Rmax_all = nan(1, nCells);
    k_all = nan(1, nCells);
    mu_deg_all = nan(1, nCells);
    mu_rad_all = nan(1, nCells);

    pref_deg_all = nan(1, nCells);
    pref_rad_all = nan(1, nCells);

    orth_deg_all = nan(1, nCells);
    R_pref_all = nan(1, nCells);
    R_orth_all = nan(1, nCells);
    OBI_all = nan(1, nCells);

    fit_error_all = nan(1, nCells);
    R2_all = nan(1, nCells);

    orientation_class_all = strings(1, nCells);

    %% Figure 1: one subplot per cell
    figure(1);
    clf;

    nRows = ceil(sqrt(nCells));
    nCols = ceil(nCells / nRows);

    sgtitle('Normalized orientation tuning curves');

    %% Figure 2: mu-OBI bidirectional vectors
    figure(2);
    clf;
    pax2 = polaraxes;
    hold(pax2, 'on');
    title(pax2, 'All cells: \mu and OBI, bidirectional');

    legendHandles2 = gobjects(1, nCells);
    legendNames2 = strings(1, nCells);

    %% Figure 3: x_pref-OBI bidirectional vectors
    figure(3);
    clf;
    pax3 = polaraxes;
    hold(pax3, 'on');
    title(pax3, 'All cells: x_{pref} and OBI, bidirectional');

    legendHandles3 = gobjects(1, nCells);
    legendNames3 = strings(1, nCells);

    %% Figure 4: horizontal vs vertical clustered x_pref-OBI vectors
    figure(4);
    clf;
    pax4 = polaraxes;
    hold(pax4, 'on');
    title(pax4, 'Clustered x_{pref}: horizontal vs vertical');

    hHorizontal = gobjects(1);
    hVertical = gobjects(1);

    %% Model function
    % p(1) = k
    % p(2) = mu, radians
    modelFun = @(p, x) exp(p(1) .* cos(2 .* (x - p(2)))) ./ exp(p(1));

    %% Angular difference for 180-degree periodic orientation, in degrees
    angleDiff180 = @(a, b) abs(mod(a - b + 90, 180) - 90);

    %% Fitting options
    options = optimoptions('lsqcurvefit', ...
        'Display', 'off', ...
        'MaxFunctionEvaluations', 5000, ...
        'MaxIterations', 1000);

    %% Loop through cells
    for i = 1:nCells

        thisColor = cellColors(i, :);

        %% Robustly read cell name
        name_i = raw{1, i};

        if isempty(name_i)
            cellNames(i) = "Cell_" + i;
        elseif isnumeric(name_i) && isscalar(name_i) && isnan(name_i)
            cellNames(i) = "Cell_" + i;
        elseif isstring(name_i) && all(strlength(name_i) == 0)
            cellNames(i) = "Cell_" + i;
        elseif ischar(name_i) && isempty(strtrim(name_i))
            cellNames(i) = "Cell_" + i;
        else
            cellNames(i) = string(name_i);
        end

        %% Read x and R
        try
            x_deg = cell2mat(raw(2:7, i));
            R = cell2mat(raw(8:13, i));
        catch
            warning('Cell %s contains non-numeric x or R. Skipped.', cellNames(i));
            continue;
        end

        x_deg = x_deg(:);
        R = R(:);

        validIdx = ~isnan(x_deg) & ~isnan(R);
        x_deg = x_deg(validIdx);
        R = R(validIdx);

        if numel(x_deg) < 4
            warning('Cell %s has fewer than 4 valid data points. Skipped.', cellNames(i));
            continue;
        end

        if max(R) == 0
            warning('Cell %s has Rmax = 0. Skipped.', cellNames(i));
            continue;
        end

        %% Normalize response
        Rmax = max(R);
        R_norm = R / Rmax;
        x_rad = deg2rad(x_deg);

        %% Initial values
        k0 = 1;
        [~, idxMax] = max(R);
        mu0 = mod(x_rad(idxMax), pi);

        p0 = [k0, mu0];

        %% Bounds
        lb = [0, 0];
        ub = [Inf, pi];

        %% Fit k and mu
        try
            p_fit = lsqcurvefit(modelFun, p0, x_rad, R_norm, lb, ub, options);
        catch ME
            warning('Fitting failed for cell %s: %s', cellNames(i), ME.message);
            continue;
        end

        k_fit = p_fit(1);
        mu_fit_rad = p_fit(2);
        mu_fit_deg = rad2deg(mu_fit_rad);

        %% Fitted curve
        x_fit_deg = linspace(0, 360, 721);
        x_fit_rad = deg2rad(x_fit_deg);
        R_fit_norm = modelFun(p_fit, x_fit_rad);

        %% Fit error and R2
        R_pred_norm = modelFun(p_fit, x_rad);

        residual = R_norm - R_pred_norm;
        fit_error = sum(residual.^2);

        SS_res = sum((R_norm - R_pred_norm).^2);
        SS_tot = sum((R_norm - mean(R_norm)).^2);

        if SS_tot > 0
            R2 = 1 - SS_res / SS_tot;
        else
            R2 = NaN;
        end

        %% Preferred direction: sampled x closest to fitted mu
        diff_to_mu = angleDiff180(x_deg, mu_fit_deg);
        [~, idxPref] = min(diff_to_mu);

        pref_deg = x_deg(idxPref);
        pref_rad = deg2rad(pref_deg);
        R_pref = R(idxPref);

        %% Orthogonal direction
        orth_target_deg = mod(pref_deg + 90, 180);

        diff_to_orth = angleDiff180(x_deg, orth_target_deg);
        [~, idxOrth] = min(diff_to_orth);

        orth_deg = x_deg(idxOrth);
        R_orth = R(idxOrth);

        %% OBI
        OBI = (R_pref - R_orth) / (R_pref + R_orth);

        %% Figure 4 cluster based on fixed horizontal / vertical axes
        pref_ori_deg = mod(pref_deg, 180);

        dist_horizontal = min(abs(pref_ori_deg - 0), abs(pref_ori_deg - 180));
        dist_vertical = abs(pref_ori_deg - 90);

        if dist_horizontal <= dist_vertical
            orientation_class = "Horizontal";
            clusterColor = [1 0 0];      % red
        else
            orientation_class = "Vertical";
            clusterColor = [0 0 1];      % blue
        end

        %% Store results
        Rmax_all(i) = Rmax;
        k_all(i) = k_fit;
        mu_deg_all(i) = mu_fit_deg;
        mu_rad_all(i) = mu_fit_rad;

        pref_deg_all(i) = pref_deg;
        pref_rad_all(i) = pref_rad;

        orth_deg_all(i) = orth_deg;
        R_pref_all(i) = R_pref;
        R_orth_all(i) = R_orth;
        OBI_all(i) = OBI;

        fit_error_all(i) = fit_error;
        R2_all(i) = R2;

        orientation_class_all(i) = orientation_class;

        %% Figure 1: one polar subplot per cell
        figure(1);

        pax1 = subplot(nRows, nCols, i, polaraxes);
        hold(pax1, 'on');

        polarplot(pax1, x_fit_rad, R_fit_norm, ...
            'LineWidth', 1.5, ...
            'Color', thisColor);

        polarplot(pax1, x_rad, R_norm, 'o', ...
            'MarkerSize', 5, ...
            'LineWidth', 1, ...
            'Color', thisColor);

        polarplot(pax1, [mu_fit_rad mu_fit_rad], [0 OBI], ...
            'LineWidth', 2, ...
            'Color', thisColor);

        polarplot(pax1, [mu_fit_rad + pi mu_fit_rad + pi], [0 OBI], ...
            'LineWidth', 2, ...
            'Color', thisColor);

        title(pax1, sprintf('%s\n\\mu=%.1f°, x_{pref}=%.1f°, OBI=%.2f', ...
            cellNames(i), mu_fit_deg, pref_deg, OBI), ...
            'Interpreter', 'tex');

        rlim(pax1, [0 1.1]);

        %% Figure 2: mu-OBI bidirectional vector
        figure(2);

        h2 = polarplot(pax2, [mu_fit_rad mu_fit_rad], [0 OBI], ...
            'LineWidth', 1.8, ...
            'Color', thisColor);

        polarplot(pax2, [mu_fit_rad + pi mu_fit_rad + pi], [0 OBI], ...
            'LineWidth', 1.8, ...
            'Color', thisColor, ...
            'HandleVisibility', 'off');

        polarplot(pax2, mu_fit_rad, OBI, 'o', ...
            'MarkerSize', 6, ...
            'LineWidth', 1.2, ...
            'Color', thisColor, ...
            'MarkerFaceColor', thisColor, ...
            'HandleVisibility', 'off');

        polarplot(pax2, mu_fit_rad + pi, OBI, 'o', ...
            'MarkerSize', 6, ...
            'LineWidth', 1.2, ...
            'Color', thisColor, ...
            'MarkerFaceColor', thisColor, ...
            'HandleVisibility', 'off');

        legendHandles2(i) = h2;
        legendNames2(i) = cellNames(i);

        %% Figure 3: x_pref-OBI bidirectional vector
        figure(3);

        h3 = polarplot(pax3, [pref_rad pref_rad], [0 OBI], ...
            'LineWidth', 1.8, ...
            'Color', thisColor);

        polarplot(pax3, [pref_rad + pi pref_rad + pi], [0 OBI], ...
            'LineWidth', 1.8, ...
            'Color', thisColor, ...
            'HandleVisibility', 'off');

        polarplot(pax3, pref_rad, OBI, 'o', ...
            'MarkerSize', 6, ...
            'LineWidth', 1.2, ...
            'Color', thisColor, ...
            'MarkerFaceColor', thisColor, ...
            'HandleVisibility', 'off');

        polarplot(pax3, pref_rad + pi, OBI, 'o', ...
            'MarkerSize', 6, ...
            'LineWidth', 1.2, ...
            'Color', thisColor, ...
            'MarkerFaceColor', thisColor, ...
            'HandleVisibility', 'off');

        legendHandles3(i) = h3;
        legendNames3(i) = cellNames(i);

        %% Figure 4: horizontal / vertical clustered x_pref-OBI vector
        figure(4);

        h4 = polarplot(pax4, [pref_rad pref_rad], [0 OBI], ...
            'LineWidth', 2.0, ...
            'Color', clusterColor);

        polarplot(pax4, [pref_rad + pi pref_rad + pi], [0 OBI], ...
            'LineWidth', 2.0, ...
            'Color', clusterColor, ...
            'HandleVisibility', 'off');

        polarplot(pax4, pref_rad, OBI, 'o', ...
            'MarkerSize', 6, ...
            'LineWidth', 1.2, ...
            'Color', clusterColor, ...
            'MarkerFaceColor', clusterColor, ...
            'HandleVisibility', 'off');

        polarplot(pax4, pref_rad + pi, OBI, 'o', ...
            'MarkerSize', 6, ...
            'LineWidth', 1.2, ...
            'Color', clusterColor, ...
            'MarkerFaceColor', clusterColor, ...
            'HandleVisibility', 'off');

        if orientation_class == "Horizontal" && ~isgraphics(hHorizontal)
            hHorizontal = h4;
        elseif orientation_class == "Vertical" && ~isgraphics(hVertical)
            hVertical = h4;
        else
            h4.HandleVisibility = 'off';
        end

        %% Export individual cell polar plot as JPG
        % Plot 360-degree responses:
        % response at x degrees is duplicated at x + 180 degrees.
        x_360_deg = [mod(x_deg(:), 360); mod(x_deg(:) + 180, 360)];
        R_360_norm = [R_norm(:); R_norm(:)];

        [x_360_sorted_deg, sortIdx360] = sort(x_360_deg);
        R_360_sorted_norm = R_360_norm(sortIdx360);

        % Close the polar curve by appending the first point at +360 degrees.
        x_360_closed_deg = [x_360_sorted_deg; x_360_sorted_deg(1) + 360];
        R_360_closed_norm = [R_360_sorted_norm; R_360_sorted_norm(1)];

        figCell = figure('Visible', 'off', ...
            'Color', 'w', ...
            'Position', [100 100 650 650]);

        paxCell = polaraxes(figCell);
        hold(paxCell, 'on');

        % Measured responses duplicated to 360 degrees, connected by curve.
        polarplot(paxCell, deg2rad(x_360_closed_deg), R_360_closed_norm, '-o', ...
            'LineWidth', 2.0, ...
            'MarkerSize', 6, ...
            'Color', thisColor, ...
            'MarkerFaceColor', thisColor);

        % Fitted curve over 360 degrees.
        polarplot(paxCell, x_fit_rad, R_fit_norm, '--', ...
            'LineWidth', 1.5, ...
            'Color', [0.25 0.25 0.25]);

        % OBI vector along fitted mu, bidirectional.
        polarplot(paxCell, [mu_fit_rad mu_fit_rad], [0 OBI], ...
            'LineWidth', 2.5, ...
            'Color', thisColor);

        polarplot(paxCell, [mu_fit_rad + pi mu_fit_rad + pi], [0 OBI], ...
            'LineWidth', 2.5, ...
            'Color', thisColor, ...
            'HandleVisibility', 'off');

        rlim(paxCell, [0 1.1]);

        title(paxCell, sprintf('%s | \\mu=%.1f° | x_{pref}=%.1f° | OBI=%.2f', ...
            cellNames(i), mu_fit_deg, pref_deg, OBI), ...
            'Interpreter', 'tex');

        legend(paxCell, {'360° duplicated response', 'Fitted curve', 'OBI vector'}, ...
            'Location', 'bestoutside');

        safeCellName = sanitizeFileName(char(cellNames(i)));
        jpgFile = fullfile(ppDir, sprintf('%03d_%s.jpg', i, safeCellName));

        try
            exportgraphics(figCell, jpgFile, 'Resolution', 300);
        catch
            saveas(figCell, jpgFile);
        end

        close(figCell);
    end

    %% Adjust Figure 2, 3, 4
    maxOBI = max(OBI_all, [], 'omitnan');

    if isempty(maxOBI) || isnan(maxOBI) || maxOBI <= 0
        maxOBI = 1;
    end

    rMaxPlot = max(1, maxOBI * 1.1);

    figure(2);
    rlim(pax2, [0 rMaxPlot]);

    validLegendIdx2 = isgraphics(legendHandles2);

    legend(pax2, ...
        legendHandles2(validLegendIdx2), ...
        cellstr(legendNames2(validLegendIdx2)), ...
        'Location', 'bestoutside');

    figure(3);
    rlim(pax3, [0 rMaxPlot]);

    validLegendIdx3 = isgraphics(legendHandles3);

    legend(pax3, ...
        legendHandles3(validLegendIdx3), ...
        cellstr(legendNames3(validLegendIdx3)), ...
        'Location', 'bestoutside');

    figure(4);
    rlim(pax4, [0 rMaxPlot]);

    legendHandles4 = [];
    legendNames4 = {};

    if isgraphics(hHorizontal)
        legendHandles4(end + 1) = hHorizontal;
        legendNames4{end + 1} = 'Horizontal-preferring cells';
    end

    if isgraphics(hVertical)
        legendHandles4(end + 1) = hVertical;
        legendNames4{end + 1} = 'Vertical-preferring cells';
    end

    if ~isempty(legendHandles4)
        legend(pax4, legendHandles4, legendNames4, ...
            'Location', 'bestoutside');
    end

    %% Figure 5: unsupervised clustering onto two orthogonal axes
    validIdx5 = ~isnan(pref_rad_all) & ~isnan(OBI_all);

    unsup_class_all = strings(1, nCells);
    unsup_axis1_deg = NaN;
    unsup_axis2_deg = NaN;

    figure(5);
    clf;
    pax5 = polaraxes;
    hold(pax5, 'on');

    if any(validIdx5)

        theta_pref = pref_rad_all(validIdx5);

        % Four-fold circular clustering:
        % This finds two orthogonal axes without assuming horizontal/vertical.
        z4 = mean(exp(1i * 4 * theta_pref));

        unsup_axis1_rad = mod(angle(z4) / 4, pi/2);
        unsup_axis2_rad = unsup_axis1_rad + pi/2;

        unsup_axis1_deg = rad2deg(unsup_axis1_rad);
        unsup_axis2_deg = rad2deg(unsup_axis2_rad);

        title(pax5, sprintf('Unsupervised orthogonal axes: %.1f° / %.1f°', ...
            unsup_axis1_deg, unsup_axis2_deg));

        hAxis1 = gobjects(1);
        hAxis2 = gobjects(1);

        for i = 1:nCells

            if ~validIdx5(i)
                continue;
            end

            pref_rad = pref_rad_all(i);
            OBI = OBI_all(i);

            pref_deg = mod(rad2deg(pref_rad), 180);

            dist_axis1 = angleDiff180(pref_deg, unsup_axis1_deg);
            dist_axis2 = angleDiff180(pref_deg, unsup_axis2_deg);

            if dist_axis1 <= dist_axis2
                unsup_class = "Axis_1";
                plotColor = [1 0 0];      % red
            else
                unsup_class = "Axis_2";
                plotColor = [0 0 1];      % blue
            end

            unsup_class_all(i) = unsup_class;

            h5 = polarplot(pax5, [pref_rad pref_rad], [0 OBI], ...
                'LineWidth', 2.0, ...
                'Color', plotColor);

            polarplot(pax5, [pref_rad + pi pref_rad + pi], [0 OBI], ...
                'LineWidth', 2.0, ...
                'Color', plotColor, ...
                'HandleVisibility', 'off');

            polarplot(pax5, pref_rad, OBI, 'o', ...
                'MarkerSize', 6, ...
                'LineWidth', 1.2, ...
                'Color', plotColor, ...
                'MarkerFaceColor', plotColor, ...
                'HandleVisibility', 'off');

            polarplot(pax5, pref_rad + pi, OBI, 'o', ...
                'MarkerSize', 6, ...
                'LineWidth', 1.2, ...
                'Color', plotColor, ...
                'MarkerFaceColor', plotColor, ...
                'HandleVisibility', 'off');

            if unsup_class == "Axis_1" && ~isgraphics(hAxis1)
                hAxis1 = h5;
            elseif unsup_class == "Axis_2" && ~isgraphics(hAxis2)
                hAxis2 = h5;
            else
                h5.HandleVisibility = 'off';
            end
        end

        % Draw the two inferred orthogonal axes as dashed lines
        polarplot(pax5, [unsup_axis1_rad unsup_axis1_rad], [0 rMaxPlot], ...
            '--', 'LineWidth', 1.5, 'Color', [1 0 0], ...
            'HandleVisibility', 'off');

        polarplot(pax5, [unsup_axis1_rad + pi unsup_axis1_rad + pi], [0 rMaxPlot], ...
            '--', 'LineWidth', 1.5, 'Color', [1 0 0], ...
            'HandleVisibility', 'off');

        polarplot(pax5, [unsup_axis2_rad unsup_axis2_rad], [0 rMaxPlot], ...
            '--', 'LineWidth', 1.5, 'Color', [0 0 1], ...
            'HandleVisibility', 'off');

        polarplot(pax5, [unsup_axis2_rad + pi unsup_axis2_rad + pi], [0 rMaxPlot], ...
            '--', 'LineWidth', 1.5, 'Color', [0 0 1], ...
            'HandleVisibility', 'off');

        rlim(pax5, [0 rMaxPlot]);

        legendHandles5 = [];
        legendNames5 = {};

        if isgraphics(hAxis1)
            legendHandles5(end + 1) = hAxis1;
            legendNames5{end + 1} = sprintf('Axis 1-preferring cells: %.1f° / %.1f°', ...
                unsup_axis1_deg, unsup_axis1_deg + 180);
        end

        if isgraphics(hAxis2)
            legendHandles5(end + 1) = hAxis2;
            legendNames5{end + 1} = sprintf('Axis 2-preferring cells: %.1f° / %.1f°', ...
                unsup_axis2_deg, unsup_axis2_deg + 180);
        end

        if ~isempty(legendHandles5)
            legend(pax5, legendHandles5, legendNames5, ...
                'Location', 'bestoutside');
        end

    else
        title(pax5, 'Unsupervised orthogonal axes: no valid cells');
    end

    %% Figure 6: unsupervised clustering into two orientation groups
    % The two groups are NOT constrained to be orthogonal.
    % For each group, the mean preferred direction is chosen to maximize
    % the summed projected OBI:
    %
    % GroupOBI = sum(OBI_i * cos(2 * (theta_i - theta_group)))

    validIdx6 = ~isnan(pref_rad_all) & ~isnan(OBI_all) & OBI_all > 0;

    unsup2_class_all = strings(1, nCells);
    unsup2_mean_dir1_deg = NaN;
    unsup2_mean_dir2_deg = NaN;
    unsup2_groupOBI1 = NaN;
    unsup2_groupOBI2 = NaN;
    unsup2_totalGroupOBI = NaN;

    figure(6);
    clf;
    pax6 = polaraxes;
    hold(pax6, 'on');
    title(pax6, 'Unsupervised 2-cluster preferred directions');

    if sum(validIdx6) >= 2

        theta6 = pref_rad_all(validIdx6);
        weight6 = OBI_all(validIdx6);

        % Weighted axial k-means clustering, K = 2.
        % This maximizes the total projected group OBI.
        [clusterIdx6, meanDir6, groupOBI6, totalGroupOBI6] = ...
            weightedAxialKMeans2(theta6, weight6, 200, 200);

        unsup2_mean_dir1_deg = rad2deg(meanDir6(1));
        unsup2_mean_dir2_deg = rad2deg(meanDir6(2));

        unsup2_groupOBI1 = groupOBI6(1);
        unsup2_groupOBI2 = groupOBI6(2);
        unsup2_totalGroupOBI = totalGroupOBI6;

        validCellIdx = find(validIdx6);

        hCluster1 = gobjects(1);
        hCluster2 = gobjects(1);

        for ii = 1:numel(validCellIdx)

            i = validCellIdx(ii);

            pref_rad = pref_rad_all(i);
            OBI = OBI_all(i);

            thisCluster = clusterIdx6(ii);

            if thisCluster == 1
                plotColor = [1 0 0];      % red
                unsup2_class_all(i) = "Cluster_1";
            else
                plotColor = [0 0 1];      % blue
                unsup2_class_all(i) = "Cluster_2";
            end

            h6 = polarplot(pax6, [pref_rad pref_rad], [0 OBI], ...
                'LineWidth', 2.0, ...
                'Color', plotColor);

            polarplot(pax6, [pref_rad + pi pref_rad + pi], [0 OBI], ...
                'LineWidth', 2.0, ...
                'Color', plotColor, ...
                'HandleVisibility', 'off');

            polarplot(pax6, pref_rad, OBI, 'o', ...
                'MarkerSize', 6, ...
                'LineWidth', 1.2, ...
                'Color', plotColor, ...
                'MarkerFaceColor', plotColor, ...
                'HandleVisibility', 'off');

            polarplot(pax6, pref_rad + pi, OBI, 'o', ...
                'MarkerSize', 6, ...
                'LineWidth', 1.2, ...
                'Color', plotColor, ...
                'MarkerFaceColor', plotColor, ...
                'HandleVisibility', 'off');

            if thisCluster == 1 && ~isgraphics(hCluster1)
                hCluster1 = h6;
            elseif thisCluster == 2 && ~isgraphics(hCluster2)
                hCluster2 = h6;
            else
                h6.HandleVisibility = 'off';
            end
        end

        % Draw mean direction of cluster 1
        polarplot(pax6, [meanDir6(1) meanDir6(1)], [0 rMaxPlot], ...
            '--', 'LineWidth', 2.0, ...
            'Color', [1 0 0], ...
            'HandleVisibility', 'off');

        polarplot(pax6, [meanDir6(1) + pi meanDir6(1) + pi], [0 rMaxPlot], ...
            '--', 'LineWidth', 2.0, ...
            'Color', [1 0 0], ...
            'HandleVisibility', 'off');

        % Draw mean direction of cluster 2
        polarplot(pax6, [meanDir6(2) meanDir6(2)], [0 rMaxPlot], ...
            '--', 'LineWidth', 2.0, ...
            'Color', [0 0 1], ...
            'HandleVisibility', 'off');

        polarplot(pax6, [meanDir6(2) + pi meanDir6(2) + pi], [0 rMaxPlot], ...
            '--', 'LineWidth', 2.0, ...
            'Color', [0 0 1], ...
            'HandleVisibility', 'off');

        rlim(pax6, [0 rMaxPlot]);

        legendHandles6 = [];
        legendNames6 = {};

        if isgraphics(hCluster1)
            legendHandles6(end + 1) = hCluster1;
            legendNames6{end + 1} = sprintf( ...
                'Cluster 1: mean %.1f°, group OBI %.3f', ...
                unsup2_mean_dir1_deg, unsup2_groupOBI1);
        end

        if isgraphics(hCluster2)
            legendHandles6(end + 1) = hCluster2;
            legendNames6{end + 1} = sprintf( ...
                'Cluster 2: mean %.1f°, group OBI %.3f', ...
                unsup2_mean_dir2_deg, unsup2_groupOBI2);
        end

        if ~isempty(legendHandles6)
            legend(pax6, legendHandles6, legendNames6, ...
                'Location', 'bestoutside');
        end

        title(pax6, sprintf( ...
            '2-cluster preferred directions, total group OBI = %.3f', ...
            unsup2_totalGroupOBI));

    else
        title(pax6, 'Unsupervised 2-cluster preferred directions: not enough valid cells');
    end

    %% Output table
    parameterNames = {
        'Rmax'
        'k'
        'mu_deg'
        'mu_rad'
        'x_pref_deg'
        'x_pref_rad'
        'orth_direction_deg'
        'R_pref'
        'R_orth'
        'OBI'
        'fit_error_SSE'
        'R2'
        'orientation_class'
        'unsupervised_axis_class'
        'unsupervised_axis1_deg'
        'unsupervised_axis2_deg'
        'unsupervised_2cluster_class'
        'unsupervised_2cluster_mean_dir1_deg'
        'unsupervised_2cluster_mean_dir2_deg'
        'unsupervised_2cluster_groupOBI1'
        'unsupervised_2cluster_groupOBI2'
        'unsupervised_2cluster_totalGroupOBI'
        };

    outputCell = cell(numel(parameterNames) + 1, nCells + 1);

    outputCell{1, 1} = 'Parameter';

    for i = 1:nCells
        outputCell{1, i + 1} = char(cellNames(i));
    end

    for r = 1:numel(parameterNames)
        outputCell{r + 1, 1} = parameterNames{r};
    end

    for c = 1:nCells
        outputCell{2,  c + 1} = Rmax_all(c);
        outputCell{3,  c + 1} = k_all(c);
        outputCell{4,  c + 1} = mu_deg_all(c);
        outputCell{5,  c + 1} = mu_rad_all(c);
        outputCell{6,  c + 1} = pref_deg_all(c);
        outputCell{7,  c + 1} = pref_rad_all(c);
        outputCell{8,  c + 1} = orth_deg_all(c);
        outputCell{9,  c + 1} = R_pref_all(c);
        outputCell{10, c + 1} = R_orth_all(c);
        outputCell{11, c + 1} = OBI_all(c);
        outputCell{12, c + 1} = fit_error_all(c);
        outputCell{13, c + 1} = R2_all(c);
        outputCell{14, c + 1} = char(orientation_class_all(c));
        outputCell{15, c + 1} = char(unsup_class_all(c));
        outputCell{16, c + 1} = unsup_axis1_deg;
        outputCell{17, c + 1} = unsup_axis2_deg;
        outputCell{18, c + 1} = char(unsup2_class_all(c));
        outputCell{19, c + 1} = unsup2_mean_dir1_deg;
        outputCell{20, c + 1} = unsup2_mean_dir2_deg;
        outputCell{21, c + 1} = unsup2_groupOBI1;
        outputCell{22, c + 1} = unsup2_groupOBI2;
        outputCell{23, c + 1} = unsup2_totalGroupOBI;
    end

    writecell(outputCell, outputFile);

    %% Return numeric results as table
    numericData = [
        Rmax_all
        k_all
        mu_deg_all
        mu_rad_all
        pref_deg_all
        pref_rad_all
        orth_deg_all
        R_pref_all
        R_orth_all
        OBI_all
        fit_error_all
        R2_all
        ];

    numericParameterNames = parameterNames(1:12);

    results = array2table(numericData, ...
        'RowNames', numericParameterNames, ...
        'VariableNames', matlab.lang.makeValidName(cellstr(cellNames)));

    fprintf('Finished fitting %d cells.\n', nCells);
    fprintf('Results saved to: %s\n', outputFile);
    fprintf('Individual cell polar JPG files saved to: %s\n', ppDir);

    fprintf('Unsupervised orthogonal axes: %.2f deg and %.2f deg\n', ...
        unsup_axis1_deg, unsup_axis2_deg);

    fprintf('Unsupervised 2-cluster means: %.2f deg and %.2f deg\n', ...
        unsup2_mean_dir1_deg, unsup2_mean_dir2_deg);

    fprintf('Unsupervised 2-cluster group OBI: %.4f and %.4f, total = %.4f\n', ...
        unsup2_groupOBI1, unsup2_groupOBI2, unsup2_totalGroupOBI);
end


function safeName = sanitizeFileName(inputName)
% sanitizeFileName
%
% Convert a cell name into a safe file name for JPG export.

    if isempty(inputName)
        safeName = 'Unnamed_Cell';
        return;
    end

    safeName = char(inputName);

    % Replace characters that are invalid or inconvenient in file names.
    safeName = regexprep(safeName, '[\\/:*?"<>|\s]+', '_');

    % Remove leading or trailing underscores.
    safeName = regexprep(safeName, '^_+|_+$', '');

    if isempty(safeName)
        safeName = 'Unnamed_Cell';
    end
end


function [idxBest, muBest, groupOBIBest, objBest] = weightedAxialKMeans2(theta, weight, nStarts, maxIter)
% weightedAxialKMeans2
%
% Weighted axial circular k-means for K = 2.
%
% theta  : preferred direction in radians
% weight : OBI of each cell
%
% Objective:
%   maximize sum of group resultant lengths:
%
%   groupOBI_j = sqrt( ...
%       sum_i w_i*cos(2*theta_i)^2 + ...
%       sum_i w_i*sin(2*theta_i)^2 )
%
% This is equivalent to choosing, for each group, the mean direction that
% maximizes the summed projected OBI:
%
%   sum_i w_i*cos(2*(theta_i - theta_group))

    if nargin < 3
        nStarts = 200;
    end

    if nargin < 4
        maxIter = 200;
    end

    theta = theta(:);
    weight = weight(:);

    validIdx = ~isnan(theta) & ~isnan(weight) & weight > 0;
    theta = theta(validIdx);
    weight = weight(validIdx);

    n = numel(theta);

    if n < 2
        error('At least two valid cells are required for two-cluster analysis.');
    end

    theta = mod(theta, pi);

    objBest = -Inf;
    idxBest = [];
    muBest = [];
    groupOBIBest = [];

    %% Candidate initializations
    initPairs = [];

    % Deterministic starts using observed directions
    for a = 1:n
        for b = a+1:n
            initPairs(end+1, :) = [theta(a), theta(b)]; %#ok<AGROW>
        end
    end

    % Random starts
    rng(1);
    randomPairs = rand(nStarts, 2) * pi;

    initPairs = [initPairs; randomPairs];

    %% Multi-start optimization
    for s = 1:size(initPairs, 1)

        mu = mod(initPairs(s, :), pi);

        idx = ones(n, 1);

        for iter = 1:maxIter

            idxOld = idx;

            %% Assignment step
            score1 = weight .* cos(2 * (theta - mu(1)));
            score2 = weight .* cos(2 * (theta - mu(2)));

            idx = ones(n, 1);
            idx(score2 > score1) = 2;

            %% Avoid empty clusters
            if numel(unique(idx)) < 2
                % Move the point that is least well represented by cluster 1.
                [~, farthestIdx] = min(abs(score1));
                idx(farthestIdx) = 2;
            end

            %% Update step
            for k = 1:2

                thisIdx = idx == k;

                C = sum(weight(thisIdx) .* cos(2 * theta(thisIdx)));
                S = sum(weight(thisIdx) .* sin(2 * theta(thisIdx)));

                if C == 0 && S == 0
                    mu(k) = rand() * pi;
                else
                    mu(k) = mod(0.5 * atan2(S, C), pi);
                end
            end

            if isequal(idx, idxOld)
                break;
            end
        end

        %% Compute objective
        groupOBI = nan(1, 2);

        for k = 1:2
            thisIdx = idx == k;

            C = sum(weight(thisIdx) .* cos(2 * theta(thisIdx)));
            S = sum(weight(thisIdx) .* sin(2 * theta(thisIdx)));

            groupOBI(k) = sqrt(C^2 + S^2);
        end

        obj = sum(groupOBI);

        %% Keep best result
        if obj > objBest

            objBest = obj;
            idxBest = idx;
            muBest = mu;
            groupOBIBest = groupOBI;

        end
    end

    %% Sort clusters by mean direction for stable output
    [muBest, order] = sort(muBest);

    idxSorted = idxBest;

    for newK = 1:2
        oldK = order(newK);
        idxSorted(idxBest == oldK) = newK;
    end

    groupOBIBest = groupOBIBest(order);
    idxBest = idxSorted;
end
