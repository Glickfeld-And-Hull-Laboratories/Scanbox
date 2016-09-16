function r = sb_echo

global sb;

fwrite(sb,uint8([hex2dec('77') hex2dec('aa') hex2dec('55')]));   
    
try
    q = dec2hex(fread(sb,3,'uint8'));
    disp('Communication Ok!')
    r = 1;
catch
    disp('Comunication FAILED!');
    r = 0;
end
