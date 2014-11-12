function ot_open()

global optotune sbconfig;

if(sbconfig.optotune)
    
    if ~isempty(optotune)
        fclose(optotune);
    end
    
    
    optotune = serial('COM7', 'BaudRate', 115200, ...
        'BytesAvailableFcnMode','byte', ...
        'InputBufferSize',1024, ...
        'OutputBufferSize',1024, ...
        'Terminator', {'LF/CR',''} , ...
        'Tag','laser');
    
    fopen(optotune);    % open it...
    
end
