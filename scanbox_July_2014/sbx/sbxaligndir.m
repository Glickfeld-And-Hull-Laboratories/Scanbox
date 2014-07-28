function sbxaligndir

d = dir('*.sbx');
for(i=1:length(d))
    try
        tic
        fn = strtok(d(i).name,'.');
        if(exist([fn '.align'])==0)
            sbxread(fn,1,1);
            global info;
            [m,T] = sbxalignx(fn,0:info.max_idx-1);   %
            save([fn '.align'],'m','T');
            sprintf('Done %s: Aligned %d images in %d min',fn,info.max_idx,round(toc/60))
        else
            sprintf('File %s is already aligned',fn)
            drawnow;
        end
    catch
        sprintf('Could not align %s',fn)
    end
end
