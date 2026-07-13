function fitResult = fPlotOBI_TwoVonMisesPolarFit_ColorGroups_HWHM(xlsxFile)
% plotOBI_TwoVonMisesPolarFit_ColorGroups_HWHM
%
% 输入:
%   xlsxFile: .xlsx 文件，包含 3 列:
%       第1列: 细胞名称，文本
%       第2列: OBI
%       第3列: 偏好角度，degree, 0-360
%
% 功能:
%   1. 每个细胞生成两个等效方向点:
%        (OBI, preferred angle)
%        (OBI, preferred angle + 180)
%
%   2. 使用两个轴向调谐函数之和拟合:
%
%        R(x) = baseline
%             + Rmax1 * exp(k1*cosd(2*(x-mu1))) / exp(k1)
%             + Rmax2 * exp(k2*cosd(2*(x-mu2))) / exp(k2)
%
%   3. 每个成分天然有两个峰:
%        mu
%        mu + 180
%
%      两个成分合计得到四个峰:
%        A = mu1
%        B = mu1 + 180
%        C = mu2
%        D = mu2 + 180
%
%   4. 根据每个细胞的偏好方向与两个拟合轴的距离，将细胞分组。
%      更接近水平轴的组标为 Horizontal，用红色。
%      更接近垂直轴的组标为 Vertical，用蓝色。
%
%   5. 计算两个方向调谐函数的半宽 HWHM:
%
%        R(x) = Rmax * exp(k*cosd(2*(x-mu))) / exp(k)
%
%      半高处:
%
%        R(mu ± h) = Rmax / 2
%
%      因此:
%
%        exp(k*cosd(2h)) / exp(k) = 1/2
%
%      整理:
%
%        cosd(2h) = 1 - log(2)/k
%
%      所以:
%
%        HWHM = h = 0.5 * acosd(1 - log(2)/k)
%
%      FWHM = 2 * HWHM
%
% 输出:
%   fitResult: 拟合参数、分组结果、半宽、R2 等。

%% ==============================
%  用户可调参数
%  ==============================

% 是否约束两个主轴近似垂直
% true:  mu2 ≈ mu1 + 90
% false: mu1 和 mu2 完全自由拟合
useOrthogonalConstraint = false;

% 如果 useOrthogonalConstraint = true，
% 允许 mu2 偏离 mu1+90 的最大角度
maxPerpDeviationDeg = 20;

% k 的范围
% k 越大，峰越尖锐；k 越小，曲线越平
minK = 0.01;
maxK = 1;

% 多起点拟合次数
nRandomStarts = 1000;

% 是否保存图片
saveFigure = false;

% 是否导出每个细胞的分组结果为 CSV
saveGroupCSV = true;

% 颜色设置
colorHorizontal = [1.00, 0.00, 0.00];  % 红色
colorVertical   = [0.00, 0.20, 1.00];  % 蓝色
colorFit        = [0.00, 0.00, 0.00];  % 黑色

%% ==============================
%  1. 读取 Excel
%  ==============================

T = readtable(xlsxFile, "VariableNamingRule", "preserve");

if width(T) < 3
    error("Excel 文件至少需要 3 列：细胞名称、OBI、偏好角度。");
end

cellName = string(T{:, 1});
OBI      = double(T{:, 2});
prefDeg  = double(T{:, 3});

validIdx = ~isnan(OBI) & ~isnan(prefDeg);

cellName = cellName(validIdx);
OBI      = OBI(validIdx);
prefDeg  = prefDeg(validIdx);

if isempty(OBI)
    error("没有有效数据。请检查 OBI 和偏好角度列。");
end

if any(OBI < 0)
    error("检测到 OBI < 0。OBI 应为非负数。");
end

nCells = numel(OBI);
prefDeg = mod(prefDeg, 360);

%% ==============================
%  2. 展开为 2n 个方向点
%  ==============================

thetaData = [prefDeg(:); mod(prefDeg(:) + 180, 360)];
rData     = [OBI(:); OBI(:)];

%% ==============================
%  3. 拟合两个轴向调谐函数
%  ==============================

yMin = min(rData);
yMax = max(rData);
yRange = yMax - yMin;

if yRange <= 0
    yRange = max(yMax, 1);
end

bestSSE = inf;
bestQ = [];

opts = optimset( ...
    "Display", "off", ...
    "MaxIter", 20000, ...
    "MaxFunEvals", 200000);

objFun = @(q) objectiveTwoVonMises( ...
    q, thetaData, rData, ...
    useOrthogonalConstraint, ...
    maxPerpDeviationDeg, ...
    minK, maxK);

%% 规则多起点
initialMuList = 0:15:165;

for mu0 = initialMuList

    if useOrthogonalConstraint
        q0 = [
            yMin, ...
            yRange / 2, ...
            yRange / 2, ...
            mu0, ...
            0, ...
            5, ...
            5];
    else
        q0 = [
            yMin, ...
            yRange / 2, ...
            yRange / 2, ...
            mu0, ...
            mod(mu0 + 90, 360), ...
            5, ...
            5];
    end

    qFit = fminsearch(objFun, q0, opts);
    sse = objFun(qFit);

    if sse < bestSSE
        bestSSE = sse;
        bestQ = qFit;
    end
end

%% 随机多起点
rng(1);

for i = 1:nRandomStarts

    if useOrthogonalConstraint
        q0 = [
            yMin + 0.2 * yRange * randn, ...
            yRange * rand, ...
            yRange * rand, ...
            360 * rand, ...
            randn, ...
            minK + (maxK - minK) * rand, ...
            minK + (maxK - minK) * rand];
    else
        q0 = [
            yMin + 0.2 * yRange * randn, ...
            yRange * rand, ...
            yRange * rand, ...
            360 * rand, ...
            360 * rand, ...
            minK + (maxK - minK) * rand, ...
            minK + (maxK - minK) * rand];
    end

    qFit = fminsearch(objFun, q0, opts);
    sse = objFun(qFit);

    if sse < bestSSE
        bestSSE = sse;
        bestQ = qFit;
    end
end

params = decodeTwoVonMisesParams( ...
    bestQ, ...
    useOrthogonalConstraint, ...
    maxPerpDeviationDeg, ...
    minK, maxK);

rFitData = twoVonMisesModel(params, thetaData);

SSE = sum((rData - rFitData).^2);
SST = sum((rData - mean(rData)).^2);

if SST > 0
    R2 = 1 - SSE / SST;
else
    R2 = NaN;
end

%% ==============================
%  4. 计算两个方向的半宽 HWHM
%  ==============================

% 对于:
%   R(x) = Rmax * exp(k*cosd(2*(x-mu))) / exp(k)
%
% 半高:
%   R(mu ± h) = Rmax / 2
%
% 得到:
%   HWHM = h = 0.5 * acosd(1 - log(2)/k)
%
% 注意:
%   如果 k 太小，则曲线在 90 度处仍高于半高，
%   即 exp(-2k) > 1/2。
%   此时严格意义上的半高宽不存在，返回 NaN。

HWHM1 = computeHWHM_fromK(params.k1);
HWHM2 = computeHWHM_fromK(params.k2);

FWHM1 = 2 * HWHM1;
FWHM2 = 2 * HWHM2;

params.HWHM1 = HWHM1;
params.HWHM2 = HWHM2;
params.FWHM1 = FWHM1;
params.FWHM2 = FWHM2;

%% ==============================
%  5. 根据拟合轴给细胞分组
%  ==============================

mu1 = params.mu1;
mu2 = params.mu2;

% 每个细胞到两个轴的轴向距离，范围 0-90 度
distToAxis1 = axialDistance180(prefDeg, mu1);
distToAxis2 = axialDistance180(prefDeg, mu2);

% 判断每个细胞更接近哪一个拟合成分
componentID = ones(nCells, 1);
componentID(distToAxis2 < distToAxis1) = 2;

% 判断两个成分中哪个是水平轴、哪个是垂直轴
% 水平轴：更接近 0/180
% 垂直轴：更接近 90/270
axis1HorizontalDistance = axialDistance180(mu1, 0);
axis2HorizontalDistance = axialDistance180(mu2, 0);

if axis1HorizontalDistance <= axis2HorizontalDistance
    horizontalComponent = 1;
    verticalComponent   = 2;
else
    horizontalComponent = 2;
    verticalComponent   = 1;
end

groupName = strings(nCells, 1);
groupColor = zeros(nCells, 3);

for i = 1:nCells
    if componentID(i) == horizontalComponent
        groupName(i) = "Horizontal";
        groupColor(i, :) = colorHorizontal;
    else
        groupName(i) = "Vertical";
        groupColor(i, :) = colorVertical;
    end
end

%% ==============================
%  6. 生成拟合曲线
%  ==============================

thetaFit = linspace(0, 360, 3000);
rFit = twoVonMisesModel(params, thetaFit);

rMax = max([rData(:); rFit(:)]);
rLim = rMax * 1.18;

if rLim <= 0
    rLim = 1;
end

%% ==============================
%  7. 极坐标绘图
%  ==============================

figure("Color", "w");
ax = polaraxes;
hold(ax, "on");

title(ax, "OBI distribution fitted by two axial tuning functions");

% 7.1 画每个细胞的双向 OBI 线段
for i = 1:nCells

    th1 = deg2rad(prefDeg(i));
    th2 = deg2rad(mod(prefDeg(i) + 180, 360));

    thisColor = groupColor(i, :);

    polarplot(ax, [th1 th1], [0 OBI(i)], ...
        "Color", thisColor, ...
        "LineWidth", 1.2);

    polarplot(ax, [th2 th2], [0 OBI(i)], ...
        "Color", thisColor, ...
        "LineWidth", 1.2);
end

% 7.2 分别画水平组和垂直组的 2n 数据点
isHorizontal = groupName == "Horizontal";
isVertical   = groupName == "Vertical";

thetaHorizontal = [
    prefDeg(isHorizontal);
    mod(prefDeg(isHorizontal) + 180, 360)
];

rHorizontal = [
    OBI(isHorizontal);
    OBI(isHorizontal)
];

thetaVertical = [
    prefDeg(isVertical);
    mod(prefDeg(isVertical) + 180, 360)
];

rVertical = [
    OBI(isVertical);
    OBI(isVertical)
];

hHorizontal = polarplot(ax, deg2rad(thetaHorizontal), rHorizontal, ...
    "o", ...
    "MarkerSize", 6, ...
    "MarkerFaceColor", colorHorizontal, ...
    "MarkerEdgeColor", "none");

hVertical = polarplot(ax, deg2rad(thetaVertical), rVertical, ...
    "o", ...
    "MarkerSize", 6, ...
    "MarkerFaceColor", colorVertical, ...
    "MarkerEdgeColor", "none");

% 7.3 画拟合曲线
hFit = polarplot(ax, deg2rad(thetaFit), rFit, ...
    "-", ...
    "Color", colorFit, ...
    "LineWidth", 2.5);

% 7.4 画四个峰中心
peakNames = ["A", "B", "C", "D"];

muA = params.mu1;
muB = mod(params.mu1 + 180, 360);
muC = params.mu2;
muD = mod(params.mu2 + 180, 360);

peakCenters = [muA, muB, muC, muD];
peakHWHM    = [HWHM1, HWHM1, HWHM2, HWHM2];

% 根据峰属于哪个组，给中心线和半宽线也上色
if horizontalComponent == 1
    peakColors = [
        colorHorizontal;
        colorHorizontal;
        colorVertical;
        colorVertical
    ];
else
    peakColors = [
        colorVertical;
        colorVertical;
        colorHorizontal;
        colorHorizontal
    ];
end

for k = 1:4

    mu = mod(peakCenters(k), 360);
    hwhm = peakHWHM(k);
    thisColor = peakColors(k, :);

    % 峰中心虚线
    polarplot(ax, deg2rad([mu mu]), [0 rLim], ...
        "--", ...
        "Color", thisColor, ...
        "LineWidth", 1.5);

    % 半宽范围：mu - HWHM 和 mu + HWHM
    if ~isnan(hwhm)

        polarplot(ax, deg2rad([mu - hwhm, mu - hwhm]), [0 rLim * 0.82], ...
            "-.", ...
            "Color", thisColor, ...
            "LineWidth", 1.1);

        polarplot(ax, deg2rad([mu + hwhm, mu + hwhm]), [0 rLim * 0.82], ...
            "-.", ...
            "Color", thisColor, ...
            "LineWidth", 1.1);

        labelText = sprintf("%s\\n%.1f^\\circ\\nHWHM=%.1f^\\circ", ...
            peakNames(k), mu, hwhm);

    else

        labelText = sprintf("%s\\n%.1f^\\circ\\nHWHM=N/A", ...
            peakNames(k), mu);

    end

    text(ax, deg2rad(mu), rLim * 1.05, labelText, ...
        "HorizontalAlignment", "center", ...
        "VerticalAlignment", "middle", ...
        "FontSize", 9, ...
        "Color", thisColor);
end

rlim(ax, [0 rLim]);

ax.ThetaZeroLocation = "right";
ax.ThetaDir = "counterclockwise";

legend(ax, ...
    [hHorizontal, hVertical, hFit], ...
    ["Horizontal group", "Vertical group", "Two-component fit"], ...
    "Location", "bestoutside");

%% ==============================
%  8. 导出每个细胞分组结果
%  ==============================

groupTable = table();
groupTable.CellName = cellName(:);
groupTable.OBI = OBI(:);
groupTable.PreferredAngle_deg = prefDeg(:);
groupTable.ComponentID = componentID(:);
groupTable.Group = groupName(:);
groupTable.DistanceToAxis1_deg = distToAxis1(:);
groupTable.DistanceToAxis2_deg = distToAxis2(:);

if saveGroupCSV
    [folderPath, baseName, ~] = fileparts(xlsxFile);

    if folderPath == ""
        folderPath = pwd;
    end

    outCSV = fullfile(folderPath, baseName + "_OBI_group_result.csv");
    writetable(groupTable, outCSV);
end

%% ==============================
%  9. 输出结果
%  ==============================

fitResult = struct();

fitResult.xlsxFile = xlsxFile;
fitResult.nCells = nCells;
fitResult.nDirectionPoints = numel(thetaData);

fitResult.model = "baseline + Rmax1*exp(k1*cosd(2*(x-mu1)))/exp(k1) + Rmax2*exp(k2*cosd(2*(x-mu2)))/exp(k2)";

fitResult.HWHM_formula = "HWHM = 0.5 * acosd(1 - log(2)/k)";
fitResult.FWHM_formula = "FWHM = 2 * HWHM";

fitResult.baseline = params.baseline;

fitResult.component1.mu_deg = params.mu1;
fitResult.component1.equivalent_peak_deg = mod(params.mu1 + 180, 360);
fitResult.component1.Rmax = params.Rmax1;
fitResult.component1.k = params.k1;
fitResult.component1.HWHM_deg = HWHM1;
fitResult.component1.FWHM_deg = FWHM1;

fitResult.component2.mu_deg = params.mu2;
fitResult.component2.equivalent_peak_deg = mod(params.mu2 + 180, 360);
fitResult.component2.Rmax = params.Rmax2;
fitResult.component2.k = params.k2;
fitResult.component2.HWHM_deg = HWHM2;
fitResult.component2.FWHM_deg = FWHM2;

fitResult.peakA_deg = muA;
fitResult.peakB_deg = muB;
fitResult.peakC_deg = muC;
fitResult.peakD_deg = muD;

fitResult.peakA_HWHM_deg = HWHM1;
fitResult.peakB_HWHM_deg = HWHM1;
fitResult.peakC_HWHM_deg = HWHM2;
fitResult.peakD_HWHM_deg = HWHM2;

fitResult.horizontalComponent = horizontalComponent;
fitResult.verticalComponent = verticalComponent;

if horizontalComponent == 1
    fitResult.horizontalAxis_deg = params.mu1;
    fitResult.horizontalAxis_HWHM_deg = HWHM1;
    fitResult.horizontalAxis_FWHM_deg = FWHM1;

    fitResult.verticalAxis_deg = params.mu2;
    fitResult.verticalAxis_HWHM_deg = HWHM2;
    fitResult.verticalAxis_FWHM_deg = FWHM2;
else
    fitResult.horizontalAxis_deg = params.mu2;
    fitResult.horizontalAxis_HWHM_deg = HWHM2;
    fitResult.horizontalAxis_FWHM_deg = FWHM2;

    fitResult.verticalAxis_deg = params.mu1;
    fitResult.verticalAxis_HWHM_deg = HWHM1;
    fitResult.verticalAxis_FWHM_deg = FWHM1;
end

fitResult.axisSeparation_deg = absCircularDistance360(muA, muC);
fitResult.axisSeparationFrom90_deg = fitResult.axisSeparation_deg - 90;

fitResult.groupTable = groupTable;

fitResult.SSE = SSE;
fitResult.R2 = R2;

fprintf("\n========== Two-component axial tuning fit ==========\n");
fprintf("Input file: %s\n", xlsxFile);
fprintf("Number of cells: %d\n", nCells);
fprintf("Number of direction points after duplication: %d\n", numel(thetaData));

fprintf("\nModel:\n");
fprintf("R(x) = baseline + Rmax1*exp(k1*cosd(2*(x-mu1)))/exp(k1)\n");
fprintf("              + Rmax2*exp(k2*cosd(2*(x-mu2)))/exp(k2)\n");

fprintf("\nHWHM formula for each component:\n");
fprintf("Given: R(x) = Rmax * exp(k*cosd(2*(x-mu))) / exp(k)\n");
fprintf("At half maximum: R(mu +/- h) = Rmax / 2\n");
fprintf("Therefore: exp(k*cosd(2h)) / exp(k) = 1/2\n");
fprintf("So: cosd(2h) = 1 - log(2)/k\n");
fprintf("HWHM = h = 0.5 * acosd(1 - log(2)/k)\n");
fprintf("FWHM = 2 * HWHM\n");

fprintf("\nComponent 1:\n");
fprintf("  peak A mu1     = %.2f deg\n", params.mu1);
fprintf("  peak B mu1+180 = %.2f deg\n", mod(params.mu1 + 180, 360));
fprintf("  Rmax1          = %.4f\n", params.Rmax1);
fprintf("  k1             = %.4f\n", params.k1);

if ~isnan(HWHM1)
    fprintf("  HWHM1          = %.4f deg\n", HWHM1);
    fprintf("  FWHM1          = %.4f deg\n", FWHM1);
else
    fprintf("  HWHM1          = N/A, k1 is too small to reach half maximum within 0-90 deg\n");
    fprintf("  FWHM1          = N/A\n");
end

fprintf("\nComponent 2:\n");
fprintf("  peak C mu2     = %.2f deg\n", params.mu2);
fprintf("  peak D mu2+180 = %.2f deg\n", mod(params.mu2 + 180, 360));
fprintf("  Rmax2          = %.4f\n", params.Rmax2);
fprintf("  k2             = %.4f\n", params.k2);

if ~isnan(HWHM2)
    fprintf("  HWHM2          = %.4f deg\n", HWHM2);
    fprintf("  FWHM2          = %.4f deg\n", FWHM2);
else
    fprintf("  HWHM2          = N/A, k2 is too small to reach half maximum within 0-90 deg\n");
    fprintf("  FWHM2          = N/A\n");
end

fprintf("\nGroup definition:\n");
fprintf("  Horizontal group color = red\n");
fprintf("  Vertical group color   = blue\n");
fprintf("  Horizontal component   = %d\n", horizontalComponent);
fprintf("  Vertical component     = %d\n", verticalComponent);
fprintf("  Horizontal axis        = %.2f deg\n", fitResult.horizontalAxis_deg);
fprintf("  Horizontal HWHM        = %.4f deg\n", fitResult.horizontalAxis_HWHM_deg);
fprintf("  Horizontal FWHM        = %.4f deg\n", fitResult.horizontalAxis_FWHM_deg);
fprintf("  Vertical axis          = %.2f deg\n", fitResult.verticalAxis_deg);
fprintf("  Vertical HWHM          = %.4f deg\n", fitResult.verticalAxis_HWHM_deg);
fprintf("  Vertical FWHM          = %.4f deg\n", fitResult.verticalAxis_FWHM_deg);

fprintf("\nGroup counts:\n");
fprintf("  Horizontal cells = %d\n", sum(groupName == "Horizontal"));
fprintf("  Vertical cells   = %d\n", sum(groupName == "Vertical"));

fprintf("\nAxis relationship:\n");
fprintf("  A-C angular separation = %.2f deg\n", fitResult.axisSeparation_deg);
fprintf("  deviation from 90 deg  = %.2f deg\n", fitResult.axisSeparationFrom90_deg);

fprintf("\nGoodness of fit:\n");
fprintf("  SSE = %.4f\n", SSE);
fprintf("  R2  = %.4f\n", R2);
fprintf("====================================================\n\n");

if saveGroupCSV
    fprintf("Group result CSV saved to:\n%s\n\n", outCSV);
end

if saveFigure
    [folderPath, baseName, ~] = fileparts(xlsxFile);

    if folderPath == ""
        folderPath = pwd;
    end

    outFig = fullfile(folderPath, baseName + "_TwoVonMisesPolarFit_ColorGroups_HWHM.jpg");
    exportgraphics(gcf, outFig, "Resolution", 300);

    fprintf("Figure saved to:\n%s\n", outFig);
end

end

%% ============================================================
%  目标函数
%  ============================================================

function sse = objectiveTwoVonMises(q, thetaData, rData, ...
    useOrthogonalConstraint, maxPerpDeviationDeg, minK, maxK)

params = decodeTwoVonMisesParams( ...
    q, ...
    useOrthogonalConstraint, ...
    maxPerpDeviationDeg, ...
    minK, maxK);

rPred = twoVonMisesModel(params, thetaData);

res = rData - rPred;
sse = sum(res .^ 2);

% baseline 不应明显为负
if params.baseline < 0
    sse = sse + 1000 * abs(params.baseline);
end

end

%% ============================================================
%  两个轴向调谐函数之和
%  ============================================================

function r = twoVonMisesModel(params, xDeg)

r1 = params.Rmax1 .* exp(params.k1 .* cosd(2 .* (xDeg - params.mu1))) ./ exp(params.k1);
r2 = params.Rmax2 .* exp(params.k2 .* cosd(2 .* (xDeg - params.mu2))) ./ exp(params.k2);

r = params.baseline + r1 + r2;

end

%% ============================================================
%  参数解析
%  ============================================================

function params = decodeTwoVonMisesParams(q, ...
    useOrthogonalConstraint, maxPerpDeviationDeg, minK, maxK)

params = struct();

params.baseline = q(1);

params.Rmax1 = abs(q(2));
params.Rmax2 = abs(q(3));

params.mu1 = mod(q(4), 360);

if useOrthogonalConstraint
    if maxPerpDeviationDeg == 0
        delta = 0;
    else
        delta = maxPerpDeviationDeg * tanh(q(5));
    end

    params.mu2 = mod(params.mu1 + 90 + delta, 360);
    params.deltaFromOrthogonal = delta;
else
    params.mu2 = mod(q(5), 360);
    params.deltaFromOrthogonal = NaN;
end

k1 = abs(q(6));
k2 = abs(q(7));

k1 = max(k1, minK);
k2 = max(k2, minK);

k1 = min(k1, maxK);
k2 = min(k2, maxK);

params.k1 = k1;
params.k2 = k2;

end

%% ============================================================
%  根据 k 计算半宽 HWHM
%  ============================================================

function HWHM = computeHWHM_fromK(k)
% 对于:
%   R(x) = Rmax * exp(k*cosd(2*(x-mu))) / exp(k)
%
% 半高条件:
%   R(mu +/- h) = Rmax / 2
%
% 推导:
%   exp(k*cosd(2h)) / exp(k) = 1/2
%   k*cosd(2h) - k = -log(2)
%   cosd(2h) = 1 - log(2)/k
%
% 因此:
%   HWHM = h = 0.5 * acosd(1 - log(2)/k)
%
% 如果 k < log(2)/2，则 1 - log(2)/k < -1，
% 此时在 0-90 度范围内曲线最低点仍高于半峰值，
% 半高宽不存在，返回 NaN。

if k <= 0
    HWHM = NaN;
    return;
end

arg = 1 - log(2) / k;

if arg < -1 || arg > 1
    HWHM = NaN;
else
    HWHM = 0.5 * acosd(arg);
end

end

%% ============================================================
%  360 度圆周角度差
%  返回范围: [-180, 180]
%  ============================================================

function d = circularDistance360(theta1, theta2)

d = mod(theta1 - theta2 + 180, 360) - 180;

end

%% ============================================================
%  360 度圆周绝对角度差
%  返回范围: [0, 180]
%  ============================================================

function dAbs = absCircularDistance360(theta1, theta2)

dAbs = abs(circularDistance360(theta1, theta2));

end

%% ============================================================
%  轴向角度距离
%  用于比较一个方向与一个 orientation 轴的距离
%  返回范围: [0, 90]
%  例如:
%     axialDistance180(10, 0)   = 10
%     axialDistance180(170, 0)  = 10
%     axialDistance180(95, 90)  = 5
%  ============================================================

function dAbs = axialDistance180(theta1, theta2)

d = mod(theta1 - theta2 + 90, 180) - 90;
dAbs = abs(d);

end