function [spikelocation, spikenum] = FindSpike(trace, spikethreshold, startp)
%UNTITLED3 Summary of this function goes here
%   **************************
%   **  Ver 1.0 2010.09.29  **
%   **************************
%   用来在给定的时间段内寻找 spike
%   -=  INPUT  =-
%   trace           待寻找的trace    
%   spikethreshold  定义Spike开始的阈值
%   startp          trace(1) 在原始数据中的位置
%
%   -=  OUTPUT  =-
%   spikelocation   返回找到的Spike的峰值的位置
%   spikenum        返回找到的Spike的总数
%
%   -=  ADDITION  =-
%   rawpeak         记录trace超过spikethreshold的点相对于trace的位置
%                   在 rawpeak 中,每一段连续的点被认为是一个Spike;
%                   连续的点的定义为 (rawpeak(i+1)-rawpeak(i) == 1)
%   spikelocation(n) = find(trace(rawpeak(sp:ep)) == min(trace(rawpeak(sp:ep))),1,'first')+rawpeak(sp)-1;
%                   min 在这里是对 SUN & HAN 的记录所定制的,
%                   主要与光敏二极管的输入电路有关,其他人也许需要修改
%          
%   Detailed explanation goes here

[length, channel] = size(trace);
spikelocation = [];

rawpeak = find(trace <= spikethreshold);
[len_rp, ch_rp] = size(rawpeak);
n = 0;
if ~isempty(rawpeak)
    sp = 1;
    ep = 0;
    for i = 1:(len_rp-1)
        if (rawpeak(i+1)-rawpeak(i) > 1)            
            ep = i;
            n = n + 1;
            spikelocation(n) = find(trace(rawpeak(sp:ep)) == min(trace(rawpeak(sp:ep))),1,'first')+rawpeak(sp)-1;
            sp = i+1;
        end;
    end
    ep = len_rp;
    n = n + 1;
    spikelocation(n) = find(trace(rawpeak(sp:ep)) == min(trace(rawpeak(sp:ep))),1,'first')+rawpeak(sp)-1;
end

spikelocation = spikelocation + startp - 1;
spikenum = n;
