clear;
c = colormap(lines);
sz = 120;
bars_w = 0.8;

fn = '!! Morph_in_S13vs15.xlsx';
d = xlsread(fn);
dj = size(d,2);
bars_x = [1 2 1 2 3 4 1 2 1 2 1 2];
for i = 1:dj
    bars_n(i) = length(find(~isnan(d(:,i))));
    bars_y(i) = mean(d(1:bars_n(i),i));
    bars_se(i) = std(d(1:bars_n(i),i))/sqrt(bars_n(i)-1);
end;
bars_c = [1 2 1 1 2 2 1 2 1 2 1 2];

%%
% Area of dendritic field (x10^4 um^2)
figure('Position',[100,100,240,400]);
hold on
for i = 1:2
    bar(bars_x(i),bars_y(i),bars_w,'Edgecolor', c(bars_c(i),:), 'FaceColor','none');
    errorbar(bars_x(i),bars_y(i),bars_se(i),'LineStyle','none','Color','k','Capsize',0);

    spots_x = ones(bars_n(i),1)*bars_x(i)+bars_w/4;
    %scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor','none','MarkerEdgeColor',c(bars_c(i),:));
    scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor',c(bars_c(i),:),'MarkerEdgeColor','none');
end;
axis([0,3,0,60000]);
plot([1,2],[57000,57000],'k');
ylabel('Area of dendritic field (x10^4 um^2)');
[h(1),p(1)] = ttest2(d(1:bars_n(1),1),d(1:bars_n(2),2));

%%
% Length of MajorAxis and MinorAxis (um)
figure('Position',[100,100,400,400]);
hold on
for i = 3:6
    bar(bars_x(i),bars_y(i),bars_w,'Edgecolor', c(bars_c(i),:), 'FaceColor','none');
    errorbar(bars_x(i),bars_y(i),bars_se(i),'LineStyle','none','Color','k','Capsize',0);

    spots_x = ones(bars_n(i),1)*bars_x(i)+bars_w/4;
    %scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor','none','MarkerEdgeColor',c(bars_c(i),:));
    scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor',c(bars_c(i),:),'MarkerEdgeColor','none');
end;
axis([0,5,0,400]);
plot([1,2],[360,360],'k');
plot([3,4],[320,320],'k');
plot([1,3],[380,380],'r');
plot([2,4],[340,340],'k');
ylabel('Length (um)');
[h(2),p(2)] = ttest2(d(1:bars_n(3),3),d(1:bars_n(4),4));    % H long-short
[h(3),p(3)] = ttest2(d(1:bars_n(5),5),d(1:bars_n(6),6));    % V long-short
[h(4),p(4)] = ttest2(d(1:bars_n(3),3),d(1:bars_n(5),5));    % Long H-V
[h(5),p(5)] = ttest2(d(1:bars_n(4),4),d(1:bars_n(6),6));    % Short H-V

%%
% Eccentricity
figure('Position',[100,100,240,400]);
hold on
for i = 7:8
    bar(bars_x(i),bars_y(i),bars_w,'Edgecolor', c(bars_c(i),:), 'FaceColor','none');
    errorbar(bars_x(i),bars_y(i),bars_se(i),'LineStyle','none','Color','k','Capsize',0);

    spots_x = ones(bars_n(i),1)*bars_x(i)+bars_w/4;
    %scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor','none','MarkerEdgeColor',c(bars_c(i),:));
    scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor',c(bars_c(i),:),'MarkerEdgeColor','none');
end;
axis([0,3,0,1]);
plot([1,2],[0.9,0.9],'k');
ylabel('Eccentricity');
[h(6),p(6)] = ttest2(d(1:bars_n(7),7),d(1:bars_n(8),8));

%%
% OBI
figure('Position',[100,100,240,400]);
hold on
for i = 9:10
    bar(bars_x(i),bars_y(i),bars_w,'Edgecolor', c(bars_c(i),:), 'FaceColor','none');
    errorbar(bars_x(i),bars_y(i),bars_se(i),'LineStyle','none','Color','k','Capsize',0);

    spots_x = ones(bars_n(i),1)*bars_x(i)+bars_w/4;
    %scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor','none','MarkerEdgeColor',c(bars_c(i),:));
    scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor',c(bars_c(i),:),'MarkerEdgeColor','none');
end;
axis([0,3,0,1]);
plot([1,2],[0.9,0.9],'r');
ylabel('OBI');
[h(7),p(7)] = ttest2(d(1:bars_n(9),9),d(1:bars_n(10),10));

%%
% OBI calculated from MajorAxis and MinorAxis
figure('Position',[100,100,240,400]);
hold on
for i = 11:12
    bar(bars_x(i),bars_y(i),bars_w,'Edgecolor', c(bars_c(i),:), 'FaceColor','none');
    errorbar(bars_x(i),bars_y(i),bars_se(i),'LineStyle','none','Color','k','Capsize',0);

    spots_x = ones(bars_n(i),1)*bars_x(i)+bars_w/4;
    %scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor','none','MarkerEdgeColor',c(bars_c(i),:));
    scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor',c(bars_c(i),:),'MarkerEdgeColor','none');
end;
axis([0,3,0,1]);
plot([1,2],[0.9,0.9],'k');
ylabel('OBI of MajorAxis and MinorAxis');
[h(8),p(8)] = ttest2(d(1:bars_n(11),11),d(1:bars_n(12),12));

%%
% X = OBI calculated from MajorAxis and MinorAxis
% Y = OBI
% LinearFit

X = d(:,11:12);
Y = d(:,9:10);
result = fLinearFitXY_MultiColumn(X, Y)