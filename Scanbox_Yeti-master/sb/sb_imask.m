function sb_imask(v)

global sb;

x = uint8(v);
fwrite(sb,uint8([64 0 v]));
