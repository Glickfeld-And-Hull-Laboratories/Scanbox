function x = sbxread(fname,k,N,varargin)

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
    
    if(exist([fname ,'.align'])) % aligned?
        info.aligned = load([fname ,'.align'],'-mat');
    else
        info.aligned = [];
    end
    
    
    info_loaded = fname;
    
    info.S = sparseint;          % sparse interpolant matrix
    
    switch info.channels
        case 1
            info.nchan = 2;      % both PMT0 & 1
            factor = 1;
        case 2
            info.nchan = 1;      % PMT 0
            factor = 2;
        case 3
            info.nchan = 1;      % PMT 1
            factor = 2;
    end
    
    info.fid = fopen([fname '.sbx']);
    d = dir([fname '.sbx']);
    info.max_idx =  d.bytes/info.bytesPerBuffer*factor - 1;
    
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

% add necessary singletons...

if(N==1)
    if(info.nchan==1)
        x = reshape(x,[1 size(x) 1]);
    else
        x = reshape(x,[size(x) 1]);
    end
else
    if(info.nchan==1)
        x = reshape(x,[1 size(x)]);
    end
end
