function r = tri_send(cmd,type,motor,value,varargin)

global tri sbconfig;

% check first if anything left to read...

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
    case 'RFS'  %% reference search
        msg(2) = 13;
    case 'RUN'  %% run application
        msg(2) = 129;
    case 'SIO'
        msg(2) = 14;
    case 'GIO'
        msg(2) = 15;
    case 'GAS'   %% get application status
        msg(2) = 135;
end

msg(3) = uint8(type);
msg(4) = uint8(motor);

v = int32(value);

for(i=0:3)
    msg(8-i) = uint8(bitand(255,bitshift(v,-8*i)));
end

msg(9) = uint8(bitand(uint32(255),sum(uint32(msg(1:8)))));

tri.Data=[uint8(1) msg]; % send command

if(nargin<5)
    while(tri.Data(1)~=0)
    end
    msg = tri.Data(2:end);
else
    msg = [];
end

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




