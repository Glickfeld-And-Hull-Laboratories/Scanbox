
function plist = sbxsegmentsub(img,lambda,nclust,mag)

% segment a subimage

mimg = mean(img,3);
th = prctile(mimg(:),20); % minimum average level percentile...

N = size(img,1);
M = size(img,2);

[xx,yy] = meshgrid(1:N,1:M);

img = reshape(img,[N*M size(img,3)]);

img(:,end+1) = lambda*xx(:);
img(:,end+1) = lambda*yy(:);


o = statset;
o.MaxIter = 150;
o.UseParallel = true;

% idx = kmeans(img,nclust,'options',o);
% idx = zeros(size(img,1),6);
% for(nrpt=1:6)
%     idx(:,nrpt) = fkmeans(img,nclust);
% end
% idx = fkmeans(idx,floor(nclust/2));

[uu,~,~] = svd(img,0);
idx = kmeans(uu(:,1:8),nclust);

clf

mimg = (mimg-min(mimg(:)))/(max(mimg(:))-min(mimg(:)))*256;
subplot(1,3,1);
imshow(mimg,gray(256));

subplot(1,3,2)
imshow(label2rgb(reshape(idx,[M N])));


%idx = fkmeans(img,nclust);

L = zeros(N,M);
clear plist;

plist = {};

k = 1;
for(i=1:nclust)
    bw = reshape(idx==i,[M N]);
    bw = imopen(bw, strel('disk',2,4));
    bw = imclearborder(bw,8);
    %bw = bwareaopen(bw,100);
    %bw = imdilate(bw,strel('disk',1));
    bw = imfill(bw,8,'holes');
    cc = regionprops(bw,'Area','Solidity','PixelIdxList','Eccentricity','PixelList');
    for(j=1:length(cc))
       mm = mean(mimg(cc(j).PixelIdxList));
       if(cc(j).Area<700*mag^2 && cc(j).Area>100*mag^2 && cc(j).Solidity>0.82 && cc(j).Eccentricity<0.9) % cell size bounds...
            L(cc(j).PixelIdxList)=k;
            plist{k} = cc(j).PixelList;
            k = k+1;
       end
    end
end

subplot(1,3,3)
imshow(label2rgb(L,'jet','k','shuffle'))

w=1;



