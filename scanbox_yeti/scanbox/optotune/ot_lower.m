function ot_lower(val)

global optotune;

mssg = zeros(1,10,'uint8');

mssg(1:4) = 'PwLA';

val = int16(val);

mssg(5) = uint8(bitand(bitshift(val,-8),255));
mssg(6) = uint8(bitand(val,255));

crc = crc16_calculate(mssg(1:8));

mssg(9) = uint8(bitand(crc,255));
mssg(10)= uint8(bitand(bitshift(crc,-8),255));

fwrite(optotune,mssg); % write the current command....

if(optotune.BytesAvailable>0)
    fread(optotune,optotune.BytesAvailable);
end

