function sb_galvo(val)

global sb T;

val = uint8(val);
fwrite(sb,uint8([hex2dec('20') val(1) val(2)]));   
 