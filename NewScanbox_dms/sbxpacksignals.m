function fnameout = sbxpacksignals(fname,odir)
%sbxpacksignals(fname,odir)
%Pack signals, i.e. downsample horizontally from 5k to 796 pixels
%if odir is empty, signal is packed into temporary folder
%global info_loaded
clear -global info_loaded info
z = sbxread1(fname,0,1);
global info;

if isfield(info,'scanbox_version') && info.scanbox_version >= 2
    %New style files, no need to pack
    fprintf('Scanbox v >= 2, file already packed\n');
    fnameout = '';
    return
    %{
    m0 = 0;
    v0 = 0;
    l0 = 0;
    , computing mean, linear trend\n');
    gl = linspace(-1,1,info.max_idx)';
    gl = gl/norm(gl);
    for delta = 0:info.max_idx-1
        z = sbxreadas(fname,delta,1,'uint16',1);
        z = squeeze(z(end,:,:));
        m0 = m0 + double(z);
        l0 = l0 + double(z)*gl(delta+1);
    end
    m0 = m0/info.max_idx;
    
    s0 = 0;
    fprintf('Scanbox v >= 2, file already packed, computing residual variance\n');
    for delta = 0:info.max_idx-1
        z = sbxreadas(fname,delta,1,'uint16',1);
        z = squeeze(z(end,:,:));
        s0 = s0 + (double(z)-m0-gl(delta+1)*l0).^2;
    end

    s0 = sqrt(s0 /info.max_idx);

    save([fname '.align'],'m0','s0','l0','gl');
    return
    %}
end

S = sparse(info.S);

[thepath,fnameroot,ext] = fileparts(fname);

if nargin == 1
    fnameout = [tempdir() fnameroot '.sbx'];
else
    fnameout = [odir '/' fnameroot '.packed'];
end

%{
if exist(fnameout,'file')
    fileinfo = dir(fnameout);
    if fileinfo.bytes == info.max_idx*size(z,2)*size(info.S,2)*2
        fprintf('Packed file already exists, exiting...\n');
        return;
    end
end
%}

ns = disk_free(fileparts(fnameout));
if ns < info.max_idx*size(z,2)*size(info.S,2)*2
    error('Not enough free disk space');
end

h = waitbar(0,sprintf('Packing signals'));

mm = fopen(fnameout,'Wb');
fseek(mm,0,0);

%m0 = 0;
%v0 = 0;

for delta = 0:info.max_idx-1
    if delta == 0
        oldtic = tic;
    end
    currtoc = toc(oldtic);
    if mod(delta,10)==0
        waitbar(delta/(info.max_idx),h,sprintf('Frame %d/%d, %.1f frames/s',delta,info.max_idx,(delta+.01)/currtoc));
    end
    
    % update waitbar...
    z = sbxread1(fname,delta,1);
    z = -double(z);
    %z = z + 2^16;
    Z = zeros(size(z,1),size(z,2),size(info.S,2),'uint16');
    for ii = 1:size(z,1);
        Z(ii,:,:) = uint16(squeeze(z(ii,:,:))*info.S);
    end
    Z = permute(Z,[1,3,2]);
    fwrite(mm,Z(:),'uint16');
end

%m0 = m0 /info.max_idx;
%v0 = v0 /info.max_idx;

%save([fname '.align'],'m0','v0');

fclose(mm);
close(h);
try
    delete(h);
catch me
    
end
