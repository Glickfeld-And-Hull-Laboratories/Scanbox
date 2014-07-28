function r = tri_send(cmd,type,motor,value)

global tri;

% check first if anything left to read...

if(tri.BytesAvailable>0)
    fread(tri,tri.BytesAvailable,'uint8');
end

msg = zeros(1,9,'uint8');

msg(1) = 1;  %% module address

switch cmd
    case 'GAP'  %% get axis param
        msg(2) = 6;
    case 'SAP'  %% set axis param
        msg(2) = 5;
    case 'ROR'  %% rotate left
        msg(2) = 1;
    case 'ROL'  %% rotate right
        msg(2) = 2;
    case 'MVP'  %% move to position
        msg(2) = 4;
    case 'MST'  %% motor stop
        msg(2) = 3;
    case 'SCO'  %% set coordinate 
        msg(2) = 30;
    case 'GCO'  %% get coordinate
        msg(2) = 31;
    case 'CCO'  %% capture coordinate 
        msg(2) = 32; 
end

msg(3) = uint8(type);
msg(4) = uint8(motor);

v = int32(value);

for(i=0:3)
    msg(8-i) = uint8(bitand(255,bitshift(v,-8*i)));
end

msg(9) = uint8(bitand(uint32(255),sum(uint32(msg(1:8)))));

fwrite(tri,msg); % send command

msg = fread(tri,9,'uint8'); %% reply....

try
    r.status = msg(3);
    value = int32(0);
    k=1;
    for(i=0:3)
        for(j=1:8)
            value = bitset(value,k,bitget(msg(8-i),j));
            k = k+1;
        end
    end
    
    r.value = value;
    
catch
    r = [];
end




