
function ot_current(val)
global optotune;

mssg = zeros(1,5,'uint8');

mssg(1) = 'A';

val = int16(val);

mssg(2) = uint8(bitand(bitshift(val,-8),255));
mssg(3) = uint8(bitand(val,255));

crc = crc16_calculate(mssg(1:3));

mssg(4) = uint8(bitand(crc,255));
mssg(5) = uint8(bitand(bitshift(crc,-8),255));

fwrite(optotune,mssg); % write the current command....

if(optotune.BytesAvailable>0)
    fread(optotune,optotune.BytesAvailable);
end

