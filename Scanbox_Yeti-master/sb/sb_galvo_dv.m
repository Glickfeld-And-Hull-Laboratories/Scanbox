function sb_galvo_dv(val)

global sb;
fwrite(sb,uint8([hex2dec('66') uint8(val) 0]));   
 