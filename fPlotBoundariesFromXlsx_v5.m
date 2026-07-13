function fPlotBoundariesFromXlsx_v5(xlsxFile)
% fPlotBoundariesFromXlsx_v5
%
% 输入：
%   xlsxFile : xlsx 文件路径
%
% xlsx 文件格式：
%   第1列：总下边界
%   第2列：总上边界
%   第3列：H组下边界
%   第4列：H组上边界
%   第5列：V组下边界
%   第6列：V组上边界
%
% 功能：
%   1. 第1、2列分别求 mean，绘制贯穿全图的水平直线
%   2. 第3–6列分别求 mean 和 SEM
%   3. 第3、4列作为第1组；第5、6列作为第2组
%   4. 每组上下界 mean 之间绘制半透明矩形
%   5. 每条上下界平均值绘制加粗线段
%   6. 绘制 SEM errorbar
%   7. 在每个平均值附近绘制对应的单个原始数据点
%   8. 单个数据点为同组颜色的实心圆，并加入 X 方向 jitter
%   9. 计算第3列 vs 第5列、第4列 vs 第6列的 ttest2 p-value
%  10. Y轴固定为 0–1
%  11. X/Y轴 tick 向内
%  12. 图像大小为 400 × 400 px

    %% ===================== 参数设置 =====================
    if nargin < 1 || isempty(xlsxFile)
        [fileName, filePath] = uigetfile( ...
            {'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, ...
            '选择输入 xlsx 文件');

        if isequal(fileName, 0)
            disp('已取消。');
            return;
        end

        xlsxFile = fullfile(filePath, fileName);
    end

    groupNames = {'H', 'V'};

    % 每组矩形和平均值线段宽度
    segmentWidth = 0.8;

    % 矩形透明度
    rectAlpha = 0.5;

    % 平均值线宽
    groupLineWidth = 4;

    % 总边界线宽
    totalLineWidth = 2;

    % SEM误差线参数
    semLineWidth = 1.5;
    capSize = 10;

    % 单个数据点参数
    pointSize = 40; %28;
    jitterWidth = 0.4; %0.28;

    % 字体参数
    fontSize = 12;
    pFontSize = 10;

    %% ===================== 读取数据 =====================
    data = readmatrix(xlsxFile);

    % 删除全 NaN 行
    data = data(~all(isnan(data), 2), :);

    nCol = size(data, 2);

    if nCol < 6
        error('xlsx 文件至少需要包含 6 列。');
    end

    %% ===================== 计算每列 mean 和 SEM =====================
    colMean = nan(1, nCol);
    colSEM  = nan(1, nCol);
    colN    = nan(1, nCol);

    for c = 1:nCol

        y = data(:, c);
        y = y(~isnan(y));

        colN(c) = numel(y);

        if colN(c) > 0
            colMean(c) = mean(y);
        end

        if colN(c) > 1
            colSEM(c) = std(y) / sqrt(colN(c));
        elseif colN(c) == 1
            colSEM(c) = 0;
        end
    end

    %% ===================== ttest2 计算 p-value =====================
    y3 = data(:, 3);
    y5 = data(:, 5);

    y4 = data(:, 4);
    y6 = data(:, 6);

    y3 = y3(~isnan(y3));
    y5 = y5(~isnan(y5));

    y4 = y4(~isnan(y4));
    y6 = y6(~isnan(y6));

    [~, p35] = ttest2(y3, y5);
    [~, p46] = ttest2(y4, y6);

    fprintf('Column 3 vs Column 5: p = %.4g\n', p35);
    fprintf('Column 4 vs Column 6: p = %.4g\n', p46);

    %% ===================== 绘图 =====================
    fig = figure('Color', 'w');
    fig.Position = [200, 200, 400, 400];

    hold on;

    colors = lines(2);

    %% ===================== 第1、2列总边界 =====================
    yline(colMean(1), '--', ...
        'Color', [0.2 0.2 0.2], ...
        'LineWidth', totalLineWidth, ...
        'Label', 'Total lower', ...
        'LabelHorizontalAlignment', 'left');

    yline(colMean(2), '--', ...
        'Color', [0.2 0.2 0.2], ...
        'LineWidth', totalLineWidth, ...
        'Label', 'Total upper', ...
        'LabelHorizontalAlignment', 'left');

    %% ===================== 绘制两组 =====================
    for i = 1:2

        xCenter = i;

        x1 = xCenter - segmentWidth / 2;
        x2 = xCenter + segmentWidth / 2;

        lowerCol = 2 + (i - 1) * 2 + 1;
        upperCol = lowerCol + 1;

        yLower = colMean(lowerCol);
        yUpper = colMean(upperCol);

        semLower = colSEM(lowerCol);
        semUpper = colSEM(upperCol);

        thisColor = colors(i, :);

        %% ---------- 获取单个数据 ----------
        lowerData = data(:, lowerCol);
        lowerData = lowerData(~isnan(lowerData));

        upperData = data(:, upperCol);
        upperData = upperData(~isnan(upperData));

        %% ---------- 半透明矩形 ----------
        patch( ...
            [x1 x2 x2 x1], ...
            [yLower yLower yUpper yUpper], ...
            thisColor, ...
            'FaceAlpha', rectAlpha, ...
            'EdgeColor', 'none');

        %% ---------- 单个原始数据点 ----------
        %
        % X方向随机 jitter
        %

        xLower = xCenter + ...
            (rand(size(lowerData)) - 0.5) * jitterWidth;

        xUpper = xCenter + ...
            (rand(size(upperData)) - 0.5) * jitterWidth;

        % 下界单个数据
        scatter( ...
            xLower, ...
            lowerData, ...
            pointSize, ...
            thisColor, ...
            'filled');

        % 上界单个数据
        scatter( ...
            xUpper, ...
            upperData, ...
            pointSize, ...
            thisColor, ...
            'filled');

        %% ---------- 平均值加粗线段 ----------
        plot( ...
            [x1 x2], ...
            [yLower yLower], ...
            '-', ...
            'Color', thisColor, ...
            'LineWidth', groupLineWidth);

        plot( ...
            [x1 x2], ...
            [yUpper yUpper], ...
            '-', ...
            'Color', thisColor, ...
            'LineWidth', groupLineWidth);

        %% ---------- SEM errorbar ----------
        errorbar( ...
            xCenter, ...
            yLower, ...
            semLower, ...
            'Color', thisColor, ...
            'LineWidth', semLineWidth, ...
            'CapSize', capSize, ...
            'Marker', 'none');

        errorbar( ...
            xCenter, ...
            yUpper, ...
            semUpper, ...
            'Color', thisColor, ...
            'LineWidth', semLineWidth, ...
            'CapSize', capSize, ...
            'Marker', 'none');

    end

    %% ===================== p-value 标注 =====================

    % 第3列 vs 第5列
    yP1 = max([ ...
        colMean(3) + colSEM(3), ...
        colMean(5) + colSEM(5)]) + 0.06;

    yP1 = min(yP1, 0.92);

    plot( ...
        [1 1 2 2], ...
        [yP1 - 0.02, yP1, yP1, yP1 - 0.02], ...
        '-k', ...
        'LineWidth', 1.2);

    text( ...
        1.5, ...
        yP1 + 0.02, ...
        sprintf('p = %.3g', p35), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', pFontSize);

    % 第4列 vs 第6列
    yP2 = max([ ...
        colMean(4) + colSEM(4), ...
        colMean(6) + colSEM(6)]) + 0.12;

    yP2 = min(yP2, 0.98);

    plot( ...
        [1 1 2 2], ...
        [yP2 - 0.02, yP2, yP2, yP2 - 0.02], ...
        '-k', ...
        'LineWidth', 1.2);

    text( ...
        1.5, ...
        yP2 + 0.02, ...
        sprintf('p = %.3g', p46), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', pFontSize);

    %% ===================== 坐标轴设置 =====================
    xlim([0 3]);
    ylim([0 1]);

    xticks([1 2]);
    xticklabels(groupNames);

    xlabel('Group');
    ylabel('IPL depth');

    box off;
    axis square;

    set(gca, ...
        'FontSize', fontSize, ...
        'LineWidth', 1.2, ...
        'TickDir', 'in');

    title('Boundary Summary');

    hold off;

end