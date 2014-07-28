function x = read_sbx(fname,k,N)

% Reads frame k to k+N-1 in file fname...

global info_loaded info

% check if already loaded...

if(isempty(info_loaded) || ~strcmp(fname,info_loaded))

    if(~isempty(info_loaded))   % try closing previous...
        try
            fclose(info.fid);
        catch
        end
    end
    
    load(fname);
    
    info_loaded = fname;
    
    switch info.channels
        case 1
            info.nchan = 2;      % both PMT0 & 1
        case 2
            info.nchan = 1;      % PMT 0
        case 3
            info.nchan = 1;      % PMT 1
    end
    
    info.fid = fopen([fname '.sbx']);
    d = dir([fname '.sbx']);
    info.max_idx =  d.bytes/info.bytesPerBuffer - 1;
    
end

if(info.fid ~= -1)
    
    nsamples = info.postTriggerSamples * info.recordsPerBuffer;
    
    if(fseek(info.fid,nsamples * 2 * k * info.nchan,'bof')==0)
        x = fread(info.fid,nsamples * info.nchan * N,'uint16');
        x = -reshape(x,[info.nchan 4 info.postTriggerSamples/4 info.recordsPerBuffer N]);
        x = squeeze(mean(x,2));

       if(info.nchan>1)
            x = permute(x,[1 3 2 4]);
        else
            x = permute(x,[2 1 3]);
        end
    else
        warning('fseek error...');
        x = [];
    end
    
else
    x = [];
end


