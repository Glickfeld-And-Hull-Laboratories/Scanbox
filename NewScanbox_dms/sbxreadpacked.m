function Z = sbxreadpacked(fname,offset,nframes)
    global info_loaded info

    % check if already loaded...

    if(isempty(info_loaded) || ~strcmp(fname,info_loaded))

        [thedir,fname0,ext] = fileparts(fname);
        if ~isempty(thedir)
            fname0 = [thedir '/' fname0];
        end
        
        if(~isempty(info_loaded))   % try closing previous...
            try
                fclose(info.fid);
            catch
            end
        end

        load(fname0);

        if(exist([fname0 ,'.align'])) % aligned?
            info.aligned = load([fname0 ,'.align'],'-mat');
        else
            info.aligned = [];
        end


        info_loaded = fname;

        info.S = sparseint;          % sparse interpolant matrix

        %EDIT Patrick:: smooth interpolant as well


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

        %info.fid = fopen([fname0 '.sbx']);
        d = dir([fname0 '.sbx']);
        %Edit Patrick: to maintain compatibility with new version
        if isfield(info,'scanbox_version') && info.scanbox_version >= 2
            info.max_idx =  d.bytes/info.recordsPerBuffer/size(info.S,2)*factor/4 - 1;
            info.nsamples = (size(info.S,2) * info.recordsPerBuffer * 2 * info.nchan);   % bytes per record 
        else
            info.max_idx =  d.bytes/info.bytesPerBuffer*factor - 1;
        end

    end
    
    try
    msize = [info.recordsPerBuffer,size(info.S,2)];
    catch
        spint = sparseint;
    msize = [info.recordsPerBuffer,size(spint,2)];
    end
    if isfield(info,'scanbox_version') && info.scanbox_version >= 2
        %New style
        fid = fopen([fname '.sbx'],'rb');
        fseek(fid,2*prod(msize)*offset*info.nchan,-1);
        Z = fread(fid,prod(msize)*nframes*info.nchan,'uint16=>uint16');
        fclose(fid);
        
        Z = reshape(Z,[msize(2:-1:1),info.nchan,nframes]);
        Z = permute(Z,[3,2,1,4]);
        Z = squeeze(Z);
        Z = intmax('uint16')-Z;
    else
        %nsamps = maxframes*496*1250;

        %fprintf('Loading pre-packed file\n');
        [~,filenameroot,ext] = fileparts(fname);

        fname0 = [tempdir() filenameroot ext '.packed'];
        if ~exist(fname0,'file')
            %Try looking in the directory itself
            fname0 = [fname '.packed'];
            if ~exist(fname0,'file')
                error('File not found');
            end
        end

        fid = fopen(fname0,'rb');
        fseek(fid,2*prod(msize)*offset,-1);
        Z = fread(fid,prod(msize)*nframes,'uint16=>uint16');
        fclose(fid);
        Z = reshape(Z,[msize,nframes]);
    end
end