function ot_frequency(val)

global optotune;

mssg = zeros(1,10,'uint8');

mssg(1:4) = 'PwFA';

val = int32(val*1000);

for(i=0:3)
    mssg(5+i) = uint8(bitand(bitshift(val,-8*(3-i)),255));
end

crc = crc16_calculate(mssg(1:8));

mssg(9) = uint8(bitand(crc,255));
mssg(10) = uint8(bitand(bitshift(crc,-8),255));

fwrite(optotune,mssg); % write the current command....

if(optotune.BytesAvailable>0)
    fread(optotune,optotune.BytesAvailable);
end

