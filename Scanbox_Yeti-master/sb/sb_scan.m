function sb_scan

global sb T;

T = double([]);              % reset timestamps
fwrite(sb,uint8([4 0 1]));   % get scanning...   allow inturrupt from TTL0
tic;

