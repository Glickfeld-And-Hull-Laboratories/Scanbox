function laser_open()

global laser sbconfig;

if ~isempty(laser)
    try
        fclose(laser);
    catch
    end
end

switch sbconfig.laser_type
    
    case 'CHAMELEON'
        
        laser = serial(sbconfig.laser_com, 'BaudRate', 19200, ...
            'BytesAvailableFcnMode','byte', ...
            'InputBufferSize',1024, ...
            'OutputBufferSize',1024, ...
            'Terminator', {'CR/LF','CR/LF'} , ...
            'Tag','laser');
        fopen(laser);    % open it...
        
        
    case 'MAITAI'
        
        laser = serial(sbconfig.laser_com, 'BaudRate', 9600, ...
            'BytesAvailableFcnMode','byte', ...
            'InputBufferSize',1024, ...
            'OutputBufferSize',1024, ...
            'Terminator', {'LF','LF'} , ...
            'Tag','laser');
        
        laser_send('TIMER:WATCHDOG 0'); % disable timer
        fopen(laser);    % open it...
               
end



