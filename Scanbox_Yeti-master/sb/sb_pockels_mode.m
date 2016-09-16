function sb_pockels_mode(mode)

global sb;

fwrite(sb,uint8([17 0 mode]));