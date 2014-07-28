function sb_galvo(val)

global sb T;

fwrite(sb,uint8([160 128 val]));   
