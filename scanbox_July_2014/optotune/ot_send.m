
function ot_send(cmd,val)

global optotune;

mssg = zeros(1,5,'uint8');
mssg(1) = cmd;

vh = dec2hex(int16(val),4);

mssg(2) = uint8(hex2dec(vh(1:2)));
mssg(3) = uint8(hex2dec(vh(3:4)));

dec2hex(mssg)

crc16_calculate(mssg(1:3))


