function sbxplotlines(sig)

t = 1:size(sig,2);
ncell = size(sig,1);

sig = (sig-min(sig(:)))/(max(sig(:))-min(sig(:)));

clf
hold on;
cmap = jet(256);
for(i=1:ncell)
    for(j=t)
        c = cmap(ceil(sig(i,j)*256),:);
        plot([j-0.5 j+0.5],[i i],'color',c,'linewidth',2);
    end
end

        
