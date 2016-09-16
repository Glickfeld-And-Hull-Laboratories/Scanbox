function sb_abort

global sb;

fwrite(sb,uint8([4 0 0])); % write 0 to control register to abort

