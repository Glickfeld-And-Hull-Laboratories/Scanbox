function sbxaligndir(varargin)

if(nargin>=1) % cell with filenames to be aligned
    for(i=1:length(varargin{1}))
        d(i).name = varargin{1}{i};
    end
else
    d = dir('*.sbx');
end

% Align all *.sbx files in the list

for(i=1:length(d))
    try
        fn = strtok(d(i).name,'.');
        if(exist([fn '.align'])==0)
            sbxread(fn,1,1);            % read one frame to read the header of the image sequence
            global info;                % this contains the information about the structure of the image
            tic
            [m,T] = sbxalignx(fn,0:info.max_idx-1);   %
            save([fn '.align'],'m','T');
            display(sprintf('Done %s: Aligned %d images in %d min',fn,info.max_idx,round(toc/60)));
        else
            sprintf('File %s is already aligned',fn)
        end
    catch
        sprintf('Could not align %s',fn)
    end
end
