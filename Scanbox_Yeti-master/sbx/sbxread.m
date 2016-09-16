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
    
    if(~isfield(info,'sz'))
        info.sz = [512 796];    % it was only sz = .... 
    end
    
    if(~isfield(info,'scanmode'))
        info.scanmode = 1;      % unidirectional
    end
    
    if(info.scanmode==0)
        info.recordsPerBuffer = info.recordsPerBuffer*2;
    end
    
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
    info.nsamples = (info.sz(2) * info.recordsPerBuffer * 2 * info.nchan);   % bytes per record 
    %Edit Patrick: to maintain compatibility with new version
    
    if isfield(info,'scanbox_version') && info.scanbox_version >= 2
        info.max_idx =  d.bytes/info.recordsPerBuffer/info.sz(2)*factor/4 - 1;
        info.nsamples = (info.sz(2) * info.recordsPerBuffer * 2 * info.nchan);   % bytes per record 
    else
        info.max_idx =  d.bytes/info.bytesPerBuffer*factor - 1;
    end
end

if(isfield(info,'fid') && info.fid ~= -1)
    
    % nsamples = info.postTriggerSamples * info.recordsPerBuffer;
        
    try
        fseek(info.fid,k*info.nsamples,'bof');
        x = fread(info.fid,info.nsamples/2 * N,'uint16=>uint16');
        x = reshape(x,[info.nchan info.sz(2) info.recordsPerBuffer  N]);
    catch
        error('Cannot read frame.  Index range likely outside of bounds.');
    end

    x = intmax('uint16')-permute(x,[1 3 2 4]);
    
else
    x = [];
end