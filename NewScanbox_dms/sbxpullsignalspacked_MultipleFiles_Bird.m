function sig = sbxpullsignalspacked_MultipleFiles_Bird(varargin)
% inputs:
% 1) name of folder and experiment:
%    (i.e. C:\DATA\Mor\blk16\03172016\blk16L\blk16L_000)
% 2) first file to read
% 3) last file to read

fname = varargin{1};
dash = find(fname=='_', 1, 'first');
Bird = fname(1:(dash-1));
day = fname((dash+1):end);
expNum = [num2str(varargin{2}, '%.3d') '-' num2str(varargin{3},'%.3d')];
curdir = cd;
experiment = [Bird,'_',day,'_',expNum];

bs = find(fname=='\', 1, 'last');
dataDir = fname(1:bs);
cd(dataDir)

for i=varargin{2}:varargin{3}
    load([fname '_' num2str(i, '%.3d') '.segment'],'-mat'); % load segmentation
end

%sbxgetinfo(fname);
sbxreadpacked(fname,0,1);
global info;

ncell = max(mask(:));

for(i=1:ncell)
    idx{i} = find(mask==i);
end

g = exp(-(-10:10).^2/2/2^2);
maskb = conv2(g,g,double(mask>0),'same')>.02;

centroids = regionprops(mask,'Centroid');
[xi,yi] = meshgrid(1:796,1:512);

idx_pil = cell(ncell,1);
for nn = 1:ncell
    for neuropilrad = 40:5:100
        M = (xi-centroids(nn).Centroid(1)).^2+(yi-centroids(nn).Centroid(2)).^2 < neuropilrad^2;
        neuropilmask = M.*~maskb;
        if nnz(neuropilmask) > 4000
            break
        end
    end
    idx_pil{nn} = find(neuropilmask);
end

sig = zeros(info.max_idx, ncell);
pil = zeros(info.max_idx, ncell);

%h = waitbar(0,sprintf('Pulling %d signals out...',ncell));
T = info.aligned.T;
for i=0:info.max_idx-1
    %waitbar(i/(info.max_idx-1),h);          % update waitbar...
    z = sbxreadpacked(fname,i,1);
    z = circshift(z,T(i+1,:)); % align the image
    for j=1:ncell                          % for each cell
        sig(i+1,j) = mean(z(idx{j}));       % pull the mean signal out...
        pil(i+1,j) = trimmean(z(idx_pil{j}),10);
    end
    
end
%delete(h);

save([fname '.signals'],'sig','pil');     % append the motion estimate data...


