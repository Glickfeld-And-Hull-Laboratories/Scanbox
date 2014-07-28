function [result] = configureLsb9440(boardHandle, valueLsb0, valueLsb1)
% Select values to output on LSB bits of an ATS9440

%call mfile with library definitions
AlazarDefs

% set default return code to indicate failure
result = false;

% read Reg_29
offset = 29;
value = uint32(0);
password = uint32(hex2dec('32145876'));
[retCode, boardHandle, value] = calllib('ATSApi', 'AlazarReadRegister', boardHandle, offset, value, password);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarReadRegister failed -- %s\n', errorToText(retCode));
    return
end

% Select output for LSB[0]
% REG_29[13..12] = 0 ==> LSB[0] = '0'  (default)
% REG_29[13..12] = 1 ==> LSB[0] = EXT TRIG input 
% REG_29[13..12] = 2 ==> LSB[0] = AUX_IN[0] input
% REG_29[13..12] = 3 ==> LSB[0] = AUX_IN[1] input

if valueLsb0 < 0 || valueLsb0 > 3
    fprintf('Error: Invalid valueLsb0 -- %d\n', valueLsb0);
    return
end

mask = uint32(bitshift(3, 12));
value = bitand(value, bitcmp(mask));
value = bitor(value, bitshift(valueLsb0, 12)); 

% select output for LSB[1]:
% REG_29[15..14] = 0 ==> LSB[1] = '0'  (default) 
% REG_29[15..14] = 1 ==> LSB[1] = EXT TRIG input
% REG_29[15..14] = 2 ==> LSB[1] = AUX_IN[0] input
% REG_29[15..14] = 3 ==> LSB[1] = AUX_IN[1] input

if valueLsb1 < 0 || valueLsb1 > 3
    fprintf('Error: Invalid valueLsb0 -- %d\n', valueLsb0);
    return
end
    
mask = uint32(bitshift(3, 14));
value = bitand(value, bitcmp(mask));
value = bitor(value, bitshift(valueLsb1, 14)); 

% write Reg 29
offset = 29;
[retCode, boardHandle] = calllib('ATSApi', 'AlazarWriteRegister', boardHandle, offset, value, password);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarWriteRegister failed -- %s\n', errorToText(retCode));
    return
end

% config AUX_IN_1 as input if either LSB[0] or LSB[1] use it...


% read Reg_15

offset = 15;
value = uint32(0);
password = uint32(hex2dec('32145876'));
[retCode, boardHandle, value] = calllib('ATSApi', 'AlazarReadRegister', boardHandle, offset, value, password);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarReadRegister failed -- %s\n', errorToText(retCode));
    return
end

% if reg_15[27]=1 -> aux_in is input, otherwise output.

mask = uint32(bitshift(1, 27));

if valueLsb0==3 || valueLsb1==3 
    value = bitor(value,mask);
else
    value = bitand(value,bitcmp(mask));
end


[retCode, boardHandle] = calllib('ATSApi', 'AlazarWriteRegister', boardHandle, offset, value, password);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarWriteRegister failed -- %s\n', errorToText(retCode));
    return
end



% Set the return code to indicate success
result = true;

end