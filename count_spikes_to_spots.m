ver = '1.07';

username = 'Sun Le';
fn = '20120531_0001_5xOS.abf';
fout = '20120531_0001_5xOS.txt';
mthreshold = 0.48;
spikethreshold = -5;
offlasting = 0;
%stiform = [1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8];
%stiform = [1 1 1];
%stiform = [1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8 9 9 9];
%stiform = [1 1 1 1 1 2 2 2 2 2 3 3 3 3 3 4 4 4 4 4 5 5 5 5 5 6 6 6 6 6 7 7 7 7 7 8 8 8 8 8];
stiform = [1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [1 2 3 4 5 6 1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [1 2 3 4 5 6 1 2 3 4 5 6];
%stiform = [1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7];
%stiform=[];
comments = 'P20-30 mouse, mark retina direction, 6 different orietation stimuli, 500x50';
%comments = 'P20-30 mouse, mark retina direction, 6 different orietation stimuli, 500x100';
%comments = 'P20-30 mouse, mark retina direction, 6 different orietation stimuli, 100x50';
%comments = 'P20-30 mouse, mark retina direction, 50..650x50 in Orthogonal';
%comments = 'P20-30 mouse, mark retina direction, 50..650x50 in Preferred';
%comments = 'P20-30 mouse, mark retina direction, 50 spot, RF test';
%comments = 'P20-30 mouse, mark retina direction, 50um spots to map receptive field';

[d,si] = abfload(fn);
frequence = 1*1000*1000/si;
[marker,markernum] = FindMarker(d(:,2),mthreshold);
ONs = [];
OFFs = [];
sumON(1:100) = 0;
sumOFF(1:100) = 0;
sumAll(1:100) = 0;

for i=1:markernum
    startp = marker(i,1);
    endp = marker(i,2);
    spikelocation = [];
    spikenum = 0;
    [spikelocation,spikenum] = FindSpike(d(startp:endp,1),spikethreshold,startp);
    ONs(i) = spikenum;
    
    startp = marker(i,2)+1;
    endp = marker(i,2)+offlasting*frequence;
    spikelocation = [];
    spikenum = 0;
    [spikelocation,spikenum] = FindSpike(d(startp:endp,1),spikethreshold,startp);
    OFFs(i) = spikenum;
end;

if (~isempty(stiform))    
    for i=1:markernum
        sumON(stiform(i)) = sumON(stiform(i)) + ONs(i);
        sumOFF(stiform(i)) = sumOFF(stiform(i)) + OFFs(i);
        sumAll(stiform(i)) = sumAll(stiform(i)) + ONs(i) + OFFs(i);
    end;
end;

ONs'
OFFs'
if (~isempty(stiform))
    sumON(1:max(stiform))'
    sumOFF(1:max(stiform))'
    sumAll(1:max(stiform))'
end;


fid = fopen(fout, 'wt');
fprintf(fid, 'Count_spikes_to_spots (Ver. %s)\n', ver);
fprintf(fid, 'Spikes to spots with different diameters (%s, %s)\n', date, username);
fprintf(fid, '\n\n\n');
fprintf(fid, '-=  Manual input  =-\n\n');
fprintf(fid, '   input filename ... %s\n\n', fn);
fprintf(fid, '   marker threshold ... %f \n\n', mthreshold);
fprintf(fid, '   spike threshold ... %f \n\n', spikethreshold);
fprintf(fid, '   OFF responses lasting (unit: second(s)) ... %f \n\n', offlasting);
fprintf(fid, '   Stimulus pattern ... \n');
fprintf(fid, '     ');
fprintf(fid, '%5d', stiform);
fprintf(fid, '\n\n');
fprintf(fid, '   Comments ... %s\n',comments);
fprintf(fid, '\n\n\n');
fprintf(fid, '-=  Program calculated  =-\n\n');
fprintf(fid, '   frequence ... %d \n\n', frequence);
fprintf(fid, '   marker number ... %d \n\n', markernum);
fprintf(fid, '   marker starting site(s) ... \n');
fprintf(fid, '     ');
fprintf(fid, '%10d', marker(:,1));
fprintf(fid, '\n\n');
fprintf(fid, '   marker ending site(s) ... \n');
fprintf(fid, '     ');
fprintf(fid, '%10d', marker(:,2));
fprintf(fid, '\n');
fprintf(fid, '\n\n\n');
fprintf(fid, '-=  Result output  =-\n\n');

if (~isempty(stiform))
    fprintf(fid, '   Sum of ONOFF response ...\n\n');
    fprintf(fid, '     %d\n', sumAll(1:max(stiform)));
    fprintf(fid, '\n');
    fprintf(fid, '   Sum of ON response ...\n\n');
    fprintf(fid, '     %d\n', sumON(1:max(stiform)));
    fprintf(fid, '\n');
    fprintf(fid, '   Sum of OFF response ...\n\n');
    fprintf(fid, '     %d\n', sumOFF(1:max(stiform)));
    fprintf(fid, '\n');
end;

fprintf(fid, '   Number of stimulus ...\n');
fprintf(fid, '     ');
fprintf(fid, '%5d\n', markernum);
fprintf(fid, '\n\n');
fprintf(fid, '   ON responses to each stimulus ...\n\n');
%fprintf(fid, '     ');
fprintf(fid, '%5d\n', ONs);
fprintf(fid, '\n\n');
fprintf(fid, '   OFF responses to each stimulus ...\n\n');
%fprintf(fid, '     ');
fprintf(fid, '%5d\n', OFFs);
fprintf(fid, '\n\n');
fclose(fid);