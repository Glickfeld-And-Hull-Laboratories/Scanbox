function sb_hsync_sign(val)

global sb;

fwrite(sb,uint8([hex2dec('80') uint8(val) 0]));