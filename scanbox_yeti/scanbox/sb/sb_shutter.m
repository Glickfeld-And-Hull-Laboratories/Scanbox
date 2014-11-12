function sb_shutter(x)

global sb;

if(x)
    fwrite(sb,uint8([16 0 1])); % open shutter uniblitz 
else 
    fwrite(sb,uint8([16 0 0])); % close it.
end