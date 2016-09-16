
% Simple example of memory mapped processing in Scanbox

% analog output 

% global ao;
% ao = daq.createSession('ni')
% addAnalogOutputChannel(ao,'Dev1',1,'Voltage');

% Open memory mapped file -- just header first
mmfile = memmapfile('scanbox.mmap','Writable',true, ... 
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);
flag = 1;

% Process all incoming frames

while(true)

    while(mmfile.Data.header(1)<0) % wait for new frame...
       
        if(mmfile.Data.header(1) == -2)   % exit if imaging stopped
            return;
        end
        
    end
        
    if(flag)    % first time format chA according to lines/colums in data
        mmfile.Format = {'int16' [1 16] 'header' ; ... 
            'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
        mchA = double(mmfile.Data.chA);
        flag = 0;
    end
    
%     mchA = mean(double(mmfile.Data.chA(:)))
 
    %ao.outputSingleScan(mchA * 1);

    mmfile.Data.header(1) = -1;    % signal Scanbox that frame has been consumed!
    
end

clear(mmfile)

