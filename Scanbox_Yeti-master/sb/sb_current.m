function sb_current(v)

global sb;

% 61.5uA per count - v is 12 bit from 0 to 4095

x = (['0111' dec2bin(v,12)]);
b1 = bin2dec(x(1:8));
b2 = bin2dec(x(9:16));
fwrite(sb,uint8([48 b1 b2]));