function sb_continuous_resonant(val)

global sb;

% set continuous resonant mode...

if(val)
    fwrite(sb,uint8([hex2dec('34') 1 0]));   
else
    fwrite(sb,uint8([hex2dec('34') 0 0]));
end


