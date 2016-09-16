function sbxmovie(fname,idx)

global info;

clf;
colormap gray;
writerObj = VideoWriter([fname '.m4v'],'MPEG-4');
writerObj.Quality = 96;
writerObj.FrameRate = 30;
open(writerObj);

for(i=1:length(idx))
    z = sbxread(fname,idx(i),1);
    z = squeeze(z);
    if(~isempty(info.aligned))
        z = circshift(z,info.aligned.T(idx(i)+1,:));
    end
    
    imshow(z(:,70:end-70));
    text(20,20,sprintf('%3.1f sec frame #%05d',idx(i)/(info.resfreq/512*(2-info.scanmode)),idx(i)),'color',[1 1 1],'fontsize',16);
    drawnow;
    frame = getframe;
    writeVideo(writerObj,frame);
    
end

close(writerObj);