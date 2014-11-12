function x = sbxread(fname,k,N,varargin)

% img = sbxread(fname,k,N,varargin)
%
% Reads from frame k to k+N-1 in file fname
% 
% fname - the file name (e.g., 'xx0_000_001')
% k     - the index of the first frame to be read.  The first index is 0.
% N     - the number of consecutive frames to read starting with k.
%
% If N>1 it returns a 4D array of size = [#pmt rows cols N] 
% If N=1 it returns a 3D array of size = [#pmt rows cols]
%
% #pmts is the number of pmt channels being sampled (1 or 2)
% rows is the number of lines in the image
% cols is the number of pixels in each line
%
% Note that these images are the raw data, not corrected for motion and
% non-uniform sampling
%
% The function also creates a global 'info' variable with additional
% informationi about the file

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
    
    %Edit Patrick: to maintain compatibility with new version
    if isfield(info,'scanbox_version') && info.scanbox_version >= 2
        info.max_idx =  d.bytes/info.recordsPerBuffer/size(info.S,2)*factor/4 - 1;
        info.nsamples = (size(info.S,2) * info.recordsPerBuffer * 2 * info.nchan);   % bytes per record 
    else
        info.max_idx =  d.bytes/info.bytesPerBuffer*factor - 1;
    end
    

end

if(isfield(info,'fid') && info.fid ~= -1)
    
    nsamples = info.postTriggerSamples * info.recordsPerBuffer;
    
    try
        fseek(info.fid,nsamples * 2 * k * info.nchan,'bof');
    catch
        %EDIT Patrick: Reopen file if closed
        info.fid = fopen([fname '.sbx']);
        fseek(info.fid,nsamples * 2 * k * info.nchan,'bof');
    end
    
    %EDIT Patrick :: optimization (2x faster)
    x_ = fread(info.fid,nsamples * info.nchan * N,'uint16'); 
    x_ = reshape(x_,[info.nchan 4 info.postTriggerSamples/4 info.recordsPerBuffer N]);
    x = -squeeze(mean(x_,2));

    if(info.nchan>1)
        x = permute(x,[1 3 2 4]);
    else
        x = permute(x,[2 1 3]);
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
