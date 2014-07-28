function sb_setmag(n)

global sb;

x = uint16(n);
fwrite(sb,uint8([3 0 n]));


