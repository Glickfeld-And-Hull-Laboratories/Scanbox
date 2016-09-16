function sb_setgain0(v)

global sb;

fwrite(sb,uint8([7 0 v]));

