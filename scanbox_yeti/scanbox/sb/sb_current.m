function sb_current(v)

global sb;

for(i=0:7)
    
    %x = (['0111' dec2bin(v,12)]);
    x = [dec2bin(i,4) dec2bin(v,12)]
    b1 = bin2dec(x(1:8));
    b2 = bin2dec(x(9:16));
    dec2bin(b1,8);
    dec2bin(b2,8);
    fwrite(sb,uint8([48 b1 b2]));
    
    pause(2);
    
end
