
function ball = sbxballmotion_tform(fn)

load(fn,'-mat');            % should be a '*_ball.mat' file

data = squeeze(data);
M = double(max(data(:)));
m = double(min(data(:)));

ball = zeros(size(data,3),3);
[opt,met] = imregconfig('monomodal');

% estimate threshold
th = zeros(1,100);
idx = round(linspace(1,size(data,3),100));
for(i=1:100)
    z = double(data(:,:,i));
    z = (z-m)/(M-m);
    th(i) = graythresh(z);
end
th = median(th);

z1 = double(data(:,:,1));
z1 = (z1-m)/(M-m);
z1 = uint8(im2bw(z1,th));
for(n=1:size(data,3)-1)
    n
    z2 = double(data(:,:,n+1));
    z2 = (z2-m)/(M-m);
    z2 = uint8(im2bw(z2,th));
    tform = imregtform(z1,z2,'rigid',opt,met);
    ball(n,:) = [tform.T(3,1:2) acosd(tform.T(1,1))];
    z1 = z2;
end

save(fn,'ball','-append');     % append the motion estimate data...