
function eye = sbxeyemotion(fn,varargin)

load(fn);          % should be a '*_eye.mat' file

if(length(varargin)>0)
    rad_range = varargin{1};
else
    rad_range = [16 35];   % range of radii to search for
end

if size(rad_range,1) == 1
    %Edit patrick - allow rad_range to change as a function of time for
    %more robust estimation, esp. with whiskers
    rad_range = ones(size(data,4),1)*rad_range;
end
    
data = squeeze(data);      % the raw images...
xc = size(data,2)/2;       % image center
yc = size(data,1)/2;
W=40;

data = data(yc-W:yc+W,xc-W:xc+W,:);
warning off;

%Edit Patrick: changed this so that struct doesn't change size every time
%while maintaining backwards compatibility

A = cell(size(data,3),1);
B = cell(size(data,3),1);
for n = 1:size(data,3)
    A{n} = [0,0];
    B{n} = [0];
end

eye = struct('Centroid',A,'Area',B);
for(n=1:size(data,3))
    [center,radii,metric] = imfindcircles(squeeze(data(:,:,n)),rad_range(n,:),'Sensitivity',0.9);
    if(isempty(center))
        eye(n).Centroid = [NaN NaN];    % could not find anything...
        eye(n).Area = NaN;
    else
        [~,idx] = max(metric);          % pick the circle with best score
        eye(n).Centroid = center(idx,:);
        eye(n).Area = 4*pi*radii(idx)^2;
    end
    
    if mod(n,100)==0
        fprintf('Frame %d/%d\n',n,size(data,3));
    end
end

Centroid = cell2mat({eye.Centroid}');
Area = cell2mat({eye.Area}');

save(fn,'eye','Centroid','Area','-append');     % append the motion estimate data...
