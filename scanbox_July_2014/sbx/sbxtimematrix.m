function T = sbxtimematrix(info)

% Computes the time (in seconds) relative to the beginning of the frame for each pixel
% The parameter 'info' should be the structure that one gets after loading the matlab file
% corresonding to the experiment (like xx0_000_000.mat)

 ts = median(diff(info.timestamps(info.event_id==48)));
 line_t = (ts/info.recordsPerBuffer)/1e6; % line period
 [col,row] = meshgrid(0:info.postTriggerSamples/4-1,0:info.recordsPerBuffer-1);
 T = row*line_t + col*4/80e6;
 S = sparseint;
 T = T*S;
 
 