function sb_optowave_init

global sb;

% reset optoidx to zero

fwrite(sb,uint8([24 0 0]));
