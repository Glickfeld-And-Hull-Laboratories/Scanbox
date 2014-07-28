
function r = sbxsegment(fn)

close all;

sbxread(fn,1,1);

global info;


% get the mag

if(isfield(info,'config'))
    mag = info.config.magnification;
    display(sprintf('Mag = x%d',mag));
else
    mag = 1;
    display(sprintf('Mag [default] = x%d',mag));
end

switch mag
    case 1
        W = 50;
    case 2
        W = 100;
    case 4
        W = 150;
end


z = sbxreadskip(fn,200,floor(info.max_idx/200));
v = std(z,[],3);

% select points based on the variance

v(1:(W+1),:) = NaN;
v(end-(W+1):end,:)=NaN;
v(:,1:(W+1)) = NaN;
v(:,end-(W+1):end)=NaN;

load('-mat',[fn '.align']);

imagesc(v); truesize; colormap gray;

nroi = 100;
P = zeros(nroi,2);
for(k=1:nroi)
    [i,j] = find(v==max(v(:)));
    P(k,:) = [i j];
    v(i-20:i+20,j-20:j+20) = NaN;
end

% [xx,yy] = meshgrid(51:50:size(v,2)-51,51:50:size(v,1)-51);
% P = [yy(:) xx(:)];

%

% segmenting

clear plist;

h = waitbar(0,'Segmenting') ;
for(i=1:size(P,1))
     waitbar(i/size(P,1),h);
     s = z(P(i,1)-W:P(i,1)+W,P(i,2)-W:P(i,2)+W,:);
     plist{i} = sbxsegmentsub(s,200,10,mag);
end
delete(h);

% put it together...

display('Stiching...')

seg = zeros(size(v));
kcell=0;
for(i=1:size(P,1))
    pl = plist{i};
    for(j=1:length(pl))
        pidx = pl{j};
        pidx = [pidx(:,2) pidx(:,1)];
        pidx = ones(size(pidx,1),1)*(P(i,:)- [(W+1) (W+1)])+pidx;
        jj = sub2ind(size(seg),pidx(:,1),pidx(:,2));
        kcell = kcell+1;
        for(k=1:length(jj))
            if(seg(jj)==0)
                seg(jj)= kcell;
            end
        end
    end
end

% contraints at the end...

cc = regionprops(seg,'Area','Solidity','PixelIdxList','Eccentricity','PixelList');

r = zeros(size(seg));

k=0;
for(j=1:length(cc))
    if(cc(j).Area<700*mag^2 && cc(j).Area>100*mag^2 && cc(j).Solidity>0.82 && cc(j).Eccentricity<0.9)
        r(cc(j).PixelIdxList) = k;
        k = k+1;
    end
end

clf
imshow(label2rgb(r,'jet','k','shuffle'))

