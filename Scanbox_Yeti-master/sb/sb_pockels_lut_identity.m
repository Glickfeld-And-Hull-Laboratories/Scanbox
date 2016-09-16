function sb_pockels_lut_identity
global sb;

% Reset to pockels identity table...

fwrite(sb,uint8([hex2dec('44') 0 0]));
