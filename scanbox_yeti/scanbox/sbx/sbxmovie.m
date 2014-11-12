function sbxmovie(fname,idx)

global info;

clf;
colormap gray;
writerObj = VideoWriter([fname '.m4v'],'MPEG-4');
writerObj.Quality = 100;
writerObj.FrameRate = 30;
open(writerObj);

for(i=1:length(idx))
    z = sbxread(fname,idx(i),1);
    z = squeeze(z);
    if(~isempty(info.aligned))
        z = circshift(z,info.aligned.T(idx(i)+1,:));
    end
    imshow(z);
    text(20,20,sprintf('%3.1f sec',idx(i)/15.6),'color',[1 1 1],'fontsize',16);
    drawnow;
    frame = getframe;
    writeVideo(writerObj,frame);
    
end

close(writerObj);