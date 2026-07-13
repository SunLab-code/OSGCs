clear;
mypath = '!! 2026\Fig1_VC_STA_S345_supp\';

fn = [mypath, '20110110_0008_OS2_VC20(40).abf'];          % outward
fn2 = [mypath, '20110110_0008_OS2_VC20(40).abf'];            % inward

fout = [mypath, '20110110_0008-08_OS_out(20)-out(20)_Ames_5k.txt'];
comments = 'Bars in 6 different orientation, 500x50 um, Ames';
%comments = 'Bars in 6 different orientation, 500x100 um';
%comments = 'Bars in 6 different orientation, 500x50 um, 200 nM TTX';
%comments = 'Bars in 6 different orientation, 500x100 um, 200 nM TTX';
%comments = 'Bars in 6 different orientation, 500x50 um, wash out';
%comments = 'Bars in orthogonal orientation, (50..650)x50 um, step 100um';
%comments = 'Bars in orthogonal orientation, (50..650)x50 um, step 100um, 200 nM TTX';
%comments = 'Bars in preferred orientation, (50..650)x50 um, step 100um';
%comments = 'Bars in preferred orientation, (50..650)x50 um, step 100um, 200 nM TTX';
%comments = 'flash in 11 different place along Pref, 100x100 um, Ames/TTX/NBQX+TTX';
%comments = 'Bars along OrthxPref, 50x500 um, SR95531';

mthreshold = 0.5;
pret = 5000;
lastt = 17500;
%stiform = [1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [7 7 7 7 7 7 1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6];
stiform = [1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [1 2 3 4 5 6 7 7 7 7 7 7];
%stiform = [1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7];
%stiform = [1 2 3 4 5 6 7 1 2 3 4 5 6 7];
%stiform = [1 2 3 4 5 6 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7];
%stiform = [1 2 3 4 5 6 7 8 9 10 11 12 12 11 10 9 8 7 6 5 4 3 2 1];
%stiform = [1 2 3 4 5 6 7 8 9 10 11 12 13 13 12 11 10 9 8 7 6 5 4 3 2 1];
%stiform = [1 2 3 4 5 6 7 8 9 10 11 11 10 9 8 7 6 5 4 3 2 1];
%stiform = [3 1 1 1 3 2 2 2];
stin = 6;
avgn = 2;   % NOTICED !!
vp(1:stin)=0;
vp2(1:stin)=0;



[d,si] = abfload(fn);
[marker,markernum] = FindMarker(d(:,2),mthreshold);
[d2,si2] = abfload(fn2);
[marker2,markernum2] = FindMarker(d2(:,2),mthreshold);
resp(1:17500,1:stin) = 0;
resp2(1:17500,1:stin) = 0;

for i=1:markernum
    startp = marker(i,1)-5000;
    endp = startp+17499;
    resp(:,stiform(i))=resp(:,stiform(i))+d(startp:endp,1);
    
    startp2 = marker2(i,1)-5000;
    endp2 = startp2+17499;
    %%if (i~=12)
        resp2(:,stiform(i))=resp2(:,stiform(i))+d2(startp2:endp2,1);
    %%end;
end

resp = resp / avgn;
resp2 = resp2 / avgn;

%{
for i=1:7
    if (i~=5)
        resp2(:,i) = resp2(:,i) / 3;
    else
        resp2(:,i) = resp2(:,i) / 2;
    end;
end;
%}

figure;
hold on;
for i=1:stin
    %figure;
    dd = (i-1)*20000;
    
    plot([1+dd:17500+dd], resp(:,i),'b');
    %hold on;
    plot([1+dd:17500+dd], resp2(:,i)+150,'r');
    plot([5001,10000]+dd,[-200,-200],'k');
    
    %axis([0,18000,15,40]);
    
    baseline = sum(resp(1:5000,i))/5000;
    %vp(i) = sum(resp(5001:15000,i))-baseline*10000;
    vp(i) = sum(resp(5001:10001,i))-baseline*5000;
  
    baseline2 = sum(resp2(1:5000,i))/5000;
    %vp2(i) = sum(resp2(5001:15000,i))-baseline2*10000;     
    vp2(i) = sum(resp2(5001:10001,i))-baseline2*5000;     

end;
plot([5001,10000]+dd,[-330,-330],'k');
plot([10000,10000]+dd,[-330,-230],'k');
axis([0,20000*stin,-350,400]); 

fid = fopen(fout, 'wt');
fprintf(fid, '%s\n', comments);
fprintf(fid, 'On-res lasts 1 s, Off-res lasts 1 s ...\n\n\n');
fprintf(fid, 'Inhibitory input ... %s\n\n',fn); 
fprintf(fid, '%20f\n', vp);
fprintf(fid, '\n\n');
fprintf(fid, '--------------------\n\n\n');
fprintf(fid, 'Excitory input ... %s\n\n',fn2); 
fprintf(fid, '%20f\n', vp2);
fclose(fid);

vp'
vp2'