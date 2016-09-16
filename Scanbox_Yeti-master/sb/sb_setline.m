function sb_setline(n)

global sb;

x = uint16(n);
fwrite(sb,uint8([2  bitshift(bitand(x,hex2dec('ff00')),-8) bitand(x,hex2dec('00ff'))]));

