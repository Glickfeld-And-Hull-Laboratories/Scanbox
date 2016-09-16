function sb_optoperiod(x)

global sb;

% set the period of the optotune in frames (0-255)

fwrite(sb,uint8([22 x 0]));
