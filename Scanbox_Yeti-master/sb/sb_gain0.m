function sb_setgain0(v)

global sb;

fwrite(sb,uint8([6 0 v]));

