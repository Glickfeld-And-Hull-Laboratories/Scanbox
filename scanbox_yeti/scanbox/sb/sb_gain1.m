function sb_setgain0(v)

global sb;

x = uint8(v);
fwrite(sb,uint8([7 0 v]));

