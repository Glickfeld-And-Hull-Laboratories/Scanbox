
function r = sbxsegmentmanual(fn)

close all;

W = 50;

sbxread(fn,1,1);

global info;
display('Reading images...');
z = sbxreadskip(fn,150,floor(info.max_idx/150));
v = std(z,[],3);

% select points based on the variance

v(1:(W+1),:) = NaN;
v(end-(W+1):end,:)=NaN;
v(:,1:(W+1)) = NaN;
v(:,end-(W+1):end)=NaN;

load('-mat',[fn '.align']);

v = (v-min(v(:)))/(max(v(:))-min(v(:)));
v = 255*v;

close all;

figure(1);
cm = gray(256);
cm(end,:) = [1 0 0];
imshow(v,cm);


[xx,yy] = meshgrid(-W:W,-W:W);
rad = sqrt(xx.^2 + yy.^2);
bidx = find(rad>W/2 & rad<W-2);


plist={};
ncell=1;
pp = round(ginput(1));
while(~isempty(pp))
    st = zeros(size(v));
    s = z(pp(2)-W:pp(2)+W,pp(1)-W:pp(1)+W,:);
    p = s(W:W+2,W:W+2,:);
    p = reshape(p,[9 size(p,3)]);
    p = squeeze(mean(p));
    s = reshape(s,[size(s,1)*size(s,2) size(s,3)]);
    d = pdist2(p,s);
    d = reshape(d,[2*W+1 2*W+1]);
    df = filter2(fspecial('gauss',5,2),d,'same');
    
    th = prctile(df(bidx),1);
    bw = df<th;
    
%     bw = im2bw(df,graythresh(df(3:end-3,3:end-3))); 
%     if(bw(W+1,W+1)==0)
%         bw = ~bw;
%     end
    %L = (df<0.5);
    %th = mean(df(bidx))-2*std(df(bidx));
    %L = df<th;
    bw = imclearborder(bw,8);
    bw = imfill(bw,8,'holes');
    bw = bwareaopen(bw,100);
    %bw = imopen(bw,strel('disk',2,4));
    cc = regionprops(bw,'Area','Solidity','PixelIdxList','Eccentricity','PixelList');
    for(k=1:length(cc))
        if(ismember(sub2ind(size(bw),W+1,W+1),cc(k).PixelIdxList))
            %if(cc(k).Area>100 && cc(k).Solidity>0.85 && cc(k).Eccentricity<0.85) % cell size bounds...
                plist{ncell} = {pp cc(k).PixelList};
                ncell = ncell+1;
            %end
        end
    end
    
    r = stich(plist,size(v),W);
    
    bw = bwperim(r);
    
    h = get(gca,'children');
    cd = get(h,'Cdata');
    cd(bw) = 256;
    set(h,'cdata',cd);
    
    figure(1);
    pp = round(ginput(1));
end

r = stich(plist,size(v),W);


function r = stich(plist,sz,W)

seg = zeros(sz);
kcell=0;
for(i=1:length(plist))
    P = plist{i}{1};
    pidx = plist{i}{2};
    pidx = [pidx(:,2) pidx(:,1)];
    pidx = ones(size(pidx,1),1)*(P(end:-1:1)- [(W+1) (W+1)])+pidx;
    jj = sub2ind(size(seg),pidx(:,1),pidx(:,2));
    delta = sum(seg(jj)) / size(pidx,1);
    if(delta<0.1)
        kcell = kcell+1;
        for(k=1:length(jj))
            if(seg(jj)==0)
                seg(jj)= kcell;
            end
        end
    end
end

r = seg;

