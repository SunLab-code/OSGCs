function result = fLinearFitXY_MultiColumn(X, Y)
% fLinearFitXY_MultiColumn
%
% 输入 X, Y，可以包含若干列。
% X(:, i) 和 Y(:, i) 为第 i 组数据。
%
% 支持不同列长度不同的情况：
%   较短的列可以用 NaN 补齐；
%   每一组拟合时会自动忽略 NaN 或 Inf。
%
% 功能：
%   1. 每一组数据分别进行线性拟合
%   2. 所有组绘制在同一张图中
%   3. 每组颜色不同，颜色来自 colormap lines
%   4. scatter 绘制空心圆，Size = 120
%   5. 画布大小为 400 × 400
%
% 用法：
%   result = fLinearFitXY_MultiColumn(X, Y);
%
% 输出：
%   result - 结构体数组，包含每组拟合参数

    % =========================
    % 输入检查
    % =========================
    if nargin < 2
        error('请输入 X 和 Y。');
    end

    if ~isnumeric(X) || ~isnumeric(Y)
        error('X 和 Y 必须是数值矩阵。');
    end

    if ~isequal(size(X), size(Y))
        error('X 和 Y 的大小必须一致。若各列长度不同，请用 NaN 补齐到相同大小。');
    end

    [numRows, numGroups] = size(X);

    if numGroups < 1
        error('X 和 Y 至少需要包含一列数据。');
    end

    % =========================
    % 检查 NaN 补齐情况
    % =========================
    fprintf('\n========== 数据检查 ==========\n');
    fprintf('X 和 Y 的矩阵大小为：%d 行 × %d 列\n', numRows, numGroups);

    for i = 1:numGroups
        Xi_raw = X(:, i);
        Yi_raw = Y(:, i);

        validIdx = isfinite(Xi_raw) & isfinite(Yi_raw);
        nValid = sum(validIdx);
        nInvalid = numRows - nValid;

        fprintf('第 %d 组：有效点 %d 个，忽略 NaN/Inf 点 %d 个\n', ...
            i, nValid, nInvalid);
    end

    fprintf('==============================\n\n');

    % =========================
    % 颜色设置
    % =========================
    colors = lines(numGroups);

    % =========================
    % 创建图窗
    % =========================
    figure('Color', 'w', 'Position', [100, 100, 400, 400]);
    hold on;

    % 初始化结果
    result = struct( ...
        'group', [], ...
        'n', [], ...
        'nIgnored', [], ...
        'slope', [], ...
        'intercept', [], ...
        'r', [], ...
        'R2', [], ...
        'adjR2', [], ...
        'pValue', [], ...
        'RMSE', [], ...
        'level', [], ...
        'equation', [], ...
        'X', [], ...
        'Y', [], ...
        'Yfit', [], ...
        'residuals', [] ...
        );

    % =========================
    % 逐组拟合和绘图
    % =========================
    for i = 1:numGroups

        Xi_raw = X(:, i);
        Yi_raw = Y(:, i);

        % --------------------------------------------------
        % 判断并去除 NaN / Inf
        % 只有 X 和 Y 同时有效的数据点才保留
        % --------------------------------------------------
        validIdx = isfinite(Xi_raw) & isfinite(Yi_raw);

        Xi = Xi_raw(validIdx);
        Yi = Yi_raw(validIdx);

        n = length(Xi);
        nIgnored = length(Xi_raw) - n;

        % 记录组号和有效点数
        result(i).group = i;
        result(i).n = n;
        result(i).nIgnored = nIgnored;

        % 如果有效点太少，则跳过拟合
        if n < 3
            warning('第 %d 组有效数据点少于 3 个，无法可靠线性拟合，已跳过拟合。', i);

            % 仍然绘制已有散点
            if n > 0
                scatter(Xi, Yi, ...
                    120, ...
                    'Marker', 'o', ...
                    'MarkerEdgeColor', 'none', ...
                    'MarkerFaceColor', colors(i, :), ...
                    'LineWidth', 1.5, ...
                    'DisplayName', sprintf('Group %d data', i));
            end

            result(i).slope = NaN;
            result(i).intercept = NaN;
            result(i).r = NaN;
            result(i).R2 = NaN;
            result(i).adjR2 = NaN;
            result(i).pValue = NaN;
            result(i).RMSE = NaN;
            result(i).level = '有效点少于3个，未拟合';
            result(i).equation = 'Not fitted';
            result(i).X = Xi;
            result(i).Y = Yi;
            result(i).Yfit = NaN(size(Yi));
            result(i).residuals = NaN(size(Yi));

            continue;
        end

        % -------------------------
        % 线性拟合 Y = kX + b
        % -------------------------
        p = polyfit(Xi, Yi, 1);
        k = p(1);
        b = p(2);

        Yfit = polyval(p, Xi);

        % -------------------------
        % 计算统计参数
        % -------------------------
        residuals = Yi - Yfit;

        SSres = sum((Yi - Yfit).^2);
        SStot = sum((Yi - mean(Yi)).^2);

        if SStot == 0
            R2 = NaN;
            adjR2 = NaN;
        else
            R2 = 1 - SSres / SStot;
            numPredictors = 1;
            adjR2 = 1 - (1 - R2) * (n - 1) / (n - numPredictors - 1);
        end

        RMSE = sqrt(mean(residuals.^2));

        % Pearson 相关系数和 p 值
        if std(Xi) == 0 || std(Yi) == 0
            r = NaN;
            pValue = NaN;
            level = 'X 或 Y 无变化，无法计算相关性';
        else
            [Rmat, Pmat] = corrcoef(Xi, Yi);
            r = Rmat(1, 2);
            pValue = Pmat(1, 2);

            % -------------------------
            % 相关性强弱判断
            % -------------------------
            absR = abs(r);

            if pValue >= 0.05
                level = '无线性相关或相关性不显著';
            else
                if absR < 0.3
                    level = '弱线性相关';
                elseif absR < 0.5
                    level = '较弱到中等线性相关';
                elseif absR < 0.7
                    level = '中等线性相关';
                elseif absR < 0.9
                    level = '强线性相关';
                else
                    level = '极强线性相关';
                end
            end
        end

        % -------------------------
        % 绘制散点：空心圆
        % -------------------------
        scatter(Xi, Yi, ...
            120, ...
            'Marker', 'o', ...
            'MarkerEdgeColor', 'none', ...
            'MarkerFaceColor', colors(i, :), ...
            'LineWidth', 1.5, ...
            'DisplayName', sprintf('Group %d data', i));

        % -------------------------
        % 绘制拟合线
        % -------------------------
        xFitLine = [0:0.0025:0.25];%linspace(min(Xi), max(Xi), 100);
        yFitLine = polyval(p, xFitLine);

        plot(xFitLine, yFitLine, ...
            'Color', colors(i, :), ...
            'LineWidth', 2, ...
            'DisplayName', sprintf('Group %d fit', i));

        % -------------------------
        % 保存结果
        % -------------------------
        result(i).slope = k;
        result(i).intercept = b;
        result(i).r = r;
        result(i).R2 = R2;
        result(i).adjR2 = adjR2;
        result(i).pValue = pValue;
        result(i).RMSE = RMSE;
        result(i).level = level;
        result(i).equation = sprintf('Y = %.4f X %+ .4f', k, b);
        result(i).X = Xi;
        result(i).Y = Yi;
        result(i).Yfit = Yfit;
        result(i).residuals = residuals;

        % -------------------------
        % 命令行输出
        % -------------------------
        fprintf('\n========== 第 %d 组线性拟合结果 ==========\n', i);
        fprintf('原始行数 = %d\n', numRows);
        fprintf('有效点数 n = %d\n', n);
        fprintf('忽略 NaN/Inf 点数 = %d\n', nIgnored);
        fprintf('拟合方程: Y = %.6f X %+ .6f\n', k, b);
        fprintf('Pearson r = %.6f\n', r);
        fprintf('R² = %.6f\n', R2);
        fprintf('Adjusted R² = %.6f\n', adjR2);
        fprintf('p value = %.6g\n', pValue);
        fprintf('RMSE = %.6f\n', RMSE);
        fprintf('相关性判断: %s\n', level);
        fprintf('=========================================\n');

    end

    % =========================
    % 图形修饰
    % =========================
    xlabel('X');
    ylabel('Y');
    title('Linear Fit of Multiple X-Y Groups');

    axis square;
    %box on;
    %grid on;

    set(gca, ...
        'FontSize', 12, ...
        'LineWidth', 1.2);

    legend('Location', 'best', 'Box', 'off');
    
    axis([0,0.25,0,1]);
    hold off;

end