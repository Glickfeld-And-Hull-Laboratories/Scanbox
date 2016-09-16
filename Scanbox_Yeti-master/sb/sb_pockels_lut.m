function sb_pockels_lut(idx,val)

global sb;

% Set entry idx of pockels lookup table to val (both uint8)

fwrite(sb,uint8([hex2dec('43') idx val]));