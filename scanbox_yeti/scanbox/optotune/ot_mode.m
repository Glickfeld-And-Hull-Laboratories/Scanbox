
function ot_mode(m)

% m = mode

% 'S' sinusoidal
% 'Q' square
% 'D' DC
% 'T' triangular

global optotune;


if(~isempty(optotune))
    mssg = zeros(1,6,'uint8');
    
    mssg(1:4) = 'Mw?A';
    mssg(3) = m;
    
    crc = crc16_calculate(mssg(1:4));
    
    mssg(5) = uint8(bitand(crc,255));
    mssg(6)= uint8(bitand(bitshift(crc,-8),255));
    
    fwrite(optotune,mssg); % write the current command....
    
    if(optotune.BytesAvailable>0)
        fread(optotune,optotune.BytesAvailable);
    end
end


