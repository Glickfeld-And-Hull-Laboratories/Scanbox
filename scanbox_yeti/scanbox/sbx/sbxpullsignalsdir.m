function sbxpullsignalsdir

d = dir('*.segment');
for(i=1:length(d))
    try
        tic
        fn = strtok(d(i).name,'.');
        if(exist([fn '.signals'])==0)
            sbxread(fn,1,1);
            global info;
            sig = sbxpullsignals(fn);       %
            save([fn '.signals'],'sig');
            sprintf('Done %s: Pulled signals for %d frames in %d min',fn,info.max_idx,round(toc/60))
        else
            sprintf('Signals for %s already exist',fn)
            drawnow;
        end
    catch
        sprintf('Could not pull signals for %s',fn)
    end
end
