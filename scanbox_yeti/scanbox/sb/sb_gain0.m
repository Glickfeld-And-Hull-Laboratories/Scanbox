function sb_setgain0(v)

global sb;

x = uint8(v);
fwrite(sb,uint8([6 0 v]));

