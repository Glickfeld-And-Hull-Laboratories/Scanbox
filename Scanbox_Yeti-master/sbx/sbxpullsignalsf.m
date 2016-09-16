function sig = sbxpullsignalsf(fname)

load([fname '.segment'],'-mat'); % load segmentation

z = sbxread(fname,1,1);

global info;

ncell = max(mask(:));

for(i=1:ncell)
    idx{i} = find(mask==i);
end

sig = zeros(info.max_idx, ncell);

h = waitbar(0,sprintf('Pulling %d signals out...',ncell));

for(i=0:info.max_idx-1)
    waitbar(i/(info.max_idx-1),h);              % print frame #
    z = sbxread(fname,i,1);
    z = squeeze(z(1,:,:));
    z = z * info.S;                             % spatial distortion correction
    z = circshift(z,info.aligned.T(i+1,:));     % align the image
    for(j=1:ncell)                              % for each cell
        sig(i+1,j) = mean(z(idx{j}));           % pull the mean signal out...
    end
end
delete(h);



