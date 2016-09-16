function sb_linescan(val)

global sb;

% set line scan mode...

if(val)
    fwrite(sb,uint8([hex2dec('35') 1 0]));   
else
    fwrite(sb,uint8([hex2dec('35') 0 0]));
end


