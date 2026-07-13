function [marker, num] = FindMarker(trace,mthreshold)
%UNTITLED2 Summary of this function goes here
%   **************************
%   **  Ver 1.0 2010.09.29  **
%   **************************
%   用来寻找 光刺激标记 的起始和结束时间
%   -=  INPUT  =-
%   trace           用来寻找的trace
%   mthreashold     定义标记开始的阈值
%
%   -=  OUTPUT  =-
%   marker(:,1)     记录标记开始的sample位
%   marker(:,2)     记录标记结束的sample位
%   num             记录标记数
%
%   -=  ADDITION  =-
%   lasting         定义：多少SAMPLE中没有信号，标记便认为结束 （目前为100）
%   (trace(i) < mthreshold) 和 (trace(i:i+lasting) > mthreshold)
%                   中的 '<' 和 '>' 是会因为记录的不同而调整，目前是按照 
%                   SUN & HAN 的纪录所定制的
%
%   Detailed explanation goes here

lasting = 100;
[length,channels] = size(trace);
%length = 100*5000; % only for 20110903_0015.abf
num = 0;
fm = 0;
for i=1:length
    if (fm == 0)
        if (trace(i) < mthreshold)
            fm = 1;
            num = num + 1;
            marker(num,1) = i;
        end;
    else
        if (trace(i:i+lasting) > mthreshold)
            fm = 0;
            marker(num,2) = i;
        end;
    end;
end;

end

