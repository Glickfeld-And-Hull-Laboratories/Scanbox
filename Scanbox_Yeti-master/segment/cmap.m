
close all

global Cz;
base = 10000;

C = single(squeeze(sbxread('d:\2pdata\gh2\gh2_000_006',base,300)));
Cz = gpuArray(squeeze(C));

global info;
for(i=1:300)
    Cz(:,:,i) = circshift(Cz(:,:,i),[info.aligned.T(base+i,:) 0]);
end

me = mean(Cz,3);
Cz = bsxfun(@minus,Cz,me);
va = mean(Cz.^2,3);
Cz = bsxfun(@rdivide,Cz,sqrt(va));
ku = mean(Cz.^4,3)-3;

cm = zeros([size(Cz,1) size(Cz,2)],'single','gpuArray');

for(m=-1:1)
    for(n=-1:1)
        if(m~=0 || n~=0)
            cm = cm+sum(Cz.*circshift(Cz,[m n 0]),3);
        end
    end
end
cm = cm/8/size(Cz,3);
     
%         
global img_h th_txt
qq = zeros([size(cm) 3]);
qq(:,:,1) = adapthisteq(gather(cm));
% me = gather(me);
% qq(:,:,3) = (me-min(me(:)))/(max(me(:))-min(me(:)));
img_h = imshow(qq);

global th;
th = 0.2;

th_txt = text(15,15,sprintf('%1.2f',th),'color','w','fontsize',14);

colormap(gray(256));
axis([1 796 1 512])
truesize

set(gcf,'WindowButtonMotionFcn',@wbmcb)
set(gcf,'WindowScrollWheelFcn',@wswcb)
set(gcf,'WindowButtonDownFcn',@wbdcb)

