function sb_setframe(n)

global sb;

x = uint16(n);
fwrite(sb,uint8([1  bitshift(bitand(x,hex2dec('ff00')),-8) bitand(x,hex2dec('00ff'))]));

