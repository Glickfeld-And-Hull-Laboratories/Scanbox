
function eye = sbxeyemotion(fn,varargin)

load(fn,'-mat');          % should be a '*_eye.mat' file

if(length(varargin)>0)
    rad_range = varargin{1};
else
    rad_range = [8 32]
end
    
data = squeeze(data);

xc = size(data,2)/2;
yc = size(data,1)/2;
W=40;

warning off;

for(n=1:size(data,3))
    [center,radii,metric] = imfindcircles(squeeze(data(yc-W:yc+W,xc-W:xc+W,n)),rad_range,'Sensitivity',1);
    if(isempty(center))
        eye(n).Centroid = [NaN NaN];
        eye(n).Area = NaN;
    else
        %[~,idx] = min(sum((repmat([W+1 W+1],[size(center,1) 1]) - center).^2,2)./metric);
        [~,idx] = max(metric);
        eye(n).Centroid = center(idx,:);
        eye(n).Area = 4*pi*radii(idx)^2;
    end
end

save(fn,'eye','-append');     % append the motion estimate data...
