function sbxadoptmask(fn1,fn2)

% Will take the segmentation from fn1 and transfer to fn2.

img1 = load([fn1 '.align'],'-mat','m','T');
img2 = load([fn2 '.align'],'-mat','m','T');

[u,v] = fftalign(img1.m,img2.m);

load([fn1 '.segment'],'-mat');
mask = circshift(mask,[u v]);

for(j=1:length(vert))
    vert{j} = ones([size(vert{j},1) 1])*[v u] + vert{j};
end

save([fn2 '.segment'],'mask','vert');

