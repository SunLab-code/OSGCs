ONs = textread('20110109_0013_ON.txt');
OFFs = textread('20110109_0013_OFF.txt');
SPOTs = textread('20110109_0013_Spot.txt');

[m, n] = size(SPOTs);

RF_ON(1:768,1:1024) = 0;
RF_OFF(1:768,1:1024) = 0;
RF_n(1:768,1:1024) = 0;

for i=1:m
    Xc = SPOTs(i,1);
    Yc = SPOTs(i,2);
    R = SPOTs(i,3);
    
    X0 = floor(Xc - R);
    Y0 = floor(Yc - R);
    Xn = ceil(Xc + R);
    Yn = ceil(Yc + R);
    
    if (X0 < 1)
        X0 = 1;
    end;
    if (Y0 < 1)
        Y0 = 1;
    end;
    if (Xn > 1024)
        X0 = 1024;
    end;
    if (Yn > 768)
        Yn = 768;
    end;
    
    for x=X0:Xn
        for y=Y0:Yn
            dis = sqrt((x-Xc)*(x-Xc)+(y-Yc)*(y-Yc));
            if (dis<=R)
                %%%
                RF_ON(y,x) = RF_ON(y,x) + ONs(i);
                RF_OFF(y,x) = RF_OFF(y,x) + OFFs(i);
                RF_n(y,x)=RF_n(y,x)+1;
            end;
        end;
    end;
end;

for x=1:1024;
    for y=1:768;
        RF_ON(y,x)=RF_ON(y,x)/RF_n(y,x);
        RF_OFF(y,x)=RF_OFF(y,x)/RF_n(y,x);
    end;
end;
imagesc(RF_ON);
RF_ON(480,520)
for i=1:75
    for j=1:100
        x0=(j-1)*10+1;
        xn=j*10;
        y0=(i-1)*10+1;
        yn=i*10;
        val = sum(sum(RF_ON(y0:yn,x0:xn)))/100;
        RF_ON(y0:yn,x0:xn)=val;
    end;
end;
figure;
imagesc(RF_ON);
RF_ON(480,520)

vv(1:6)=0;
mm(1:768,1:1024)=0;
xx = 475;
yy = 606;
for k=0:5
    for i=-25:25
        for j=-250:250
            rr = sqrt(i*i+j*j);
            if (rr>0)
                if (j>=0)
                    deg = acos(i/rr)/pi*180;
                else
                    if (i>=0)
                        deg = 360-acos(i/rr)/pi*180;
                    else
                        deg = -acos(i/rr)/pi*180;
                    end
                end
                deg=deg+k*30;
                rad=deg/180*pi;                
                xt = round(xx+rr*cos(rad));
                yt = round(yy+rr*sin(rad));
            else
                xt=xx;
                yt=yy;
            end;
            if RF_ON(xt,yt)>0
                vv(k+1) = vv(k+1) + RF_ON(xt,yt);
                mm(xt,yt) = 100;
            end;
        end;
    end;
end;
vv'
figure;
imagesc(mm);
