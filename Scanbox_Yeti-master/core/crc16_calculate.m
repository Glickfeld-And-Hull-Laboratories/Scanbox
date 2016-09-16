
function crc = crc16_calculate(mssg)

crc = uint16(0);
for(i=1:length(mssg))
    crc = crc16_update(crc,mssg(i));
end

function crc = crc16_update(crc,a)

crc = uint16(crc);
a = uint16(a);

crc = bitxor(crc,a);

for (i = 0:7)
    if (bitand(crc,1))
        crc = bitxor(bitshift(crc,-1),hex2dec('A001'));
    else
        crc = bitshift(crc,-1);
    end
end
