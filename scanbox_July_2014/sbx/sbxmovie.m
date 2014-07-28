function sbxmovie(fname,idx,sflag)

global info;

if(sflag)
    load([fname '.mask'],'-mat');
    mboundary = bwperim(mask,8);
    bndidx = find(mboundary);
end

cm = gray(256);
cm(end,:) = [ 1 0 0];
colormap(cm);

writerObj = VideoWriter([fname '.m4v'],'MPEG-4');
writerObj.Quality = 95;
writerObj.FrameRate = 30;

open(writerObj);

for(i=1:length(idx))
    z = sbxread(fname,idx(i),1);
    z = squeeze(z(1,:,:));
    z = squeeze(z)*info.S;
    z = circshift(z,info.aligned.T(idx(i)+1,:));
    z = (z+65535)/65535;
%     if(i==1)
%         acc=z;
%     else
%         acc = 0.5*acc+0.5*z; % temporal smoothing...
%     end
    acc = 255*z;
    if(sflag)
        acc(bndidx)=256;
    end
    imshow(acc,cm);
    text(20,20,sprintf('%3.1f sec',idx(i)/15.6),'color',[1 1 1],'fontsize',16);
    drawnow;
    frame = getframe;
    
    writeVideo(writerObj,frame);
    
end

       
close(writerObj);