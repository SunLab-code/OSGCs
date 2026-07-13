clear;
c = colormap(lines);
sz = 80;
bars_w = 0.8;

fn = '!! S345_H_VC.xlsx';
d = xlsread(fn);
dj = size(d,2);
bars_x = [1 2 1 2];
for i = 1:dj
    bars_n(i) = length(find(~isnan(d(:,i))));
    bars_y(i) = mean(d(1:bars_n(i),i));
    bars_se(i) = std(d(1:bars_n(i),i))/sqrt(bars_n(i)-1);
end;
bars_c = [1 2 1 2];
bars_shift = [1 -1 1 -1];

%%
% Area of dendritic field (x10^4 um^2)
figure('Position',[100,100,240,400]);
hold on
for i = 1:4
    bar(bars_x(i),bars_y(i),bars_w,'Edgecolor', c(bars_c(i),:), 'FaceColor','none');
    errorbar(bars_x(i),bars_y(i),bars_se(i),'LineStyle','none','Color','k','Capsize',0);

    spots_x = ones(bars_n(i),1)*bars_x(i)+bars_w/4*bars_shift(i);
    xx(:,i) = spots_x;
    %scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor','none','MarkerEdgeColor',c(bars_c(i),:));
    scatter(spots_x, d(1:bars_n(i),i), sz,'MarkerFaceColor',c(bars_c(i),:),'MarkerEdgeColor','none');
end;
axis([0,3,-500,600]);
plot([1,2],[550,550],'k');
plot([1,2],[-400,-400],'r');

ylabel('Amplitude (pA)');
for i = 1:bars_n(1)
    plot(xx(i,1:2),d(i,1:2),'k');
    plot(xx(i,3:4),d(i,3:4),'k');
end;
[h(1),p(1)] = ttest(d(1:bars_n(1),1),d(1:bars_n(2),2));
[h(2),p(2)] = ttest(d(1:bars_n(3),3),d(1:bars_n(4),4));