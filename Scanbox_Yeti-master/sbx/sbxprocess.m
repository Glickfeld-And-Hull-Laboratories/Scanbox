function sbxprocess(fn)

if(isstr(fn) && exist([fn '.sbx'],'file'))
    
    sbxread(fn,1,1);
    
    global info;
    
    display(['Processing ' fn]);
    
    % Align
    
    try
        if(~exist([fn '.align'],'file'))
            display('Aligning... ');
            [m,T] = sbxalignx(fn,0:info.max_idx-1);
            save([fn '.align'],'m','T');
        else
            display('Images have already been aligned --> Skip');
        end
    catch
        display('Error while aligning...');
    end
    
    
    % Segment
    
    try
        clear info global;  % force a new read...
        if(~exist([fn '.segment'],'file'))
            display('Segmenting... ');
            mask = sbxsegment(fn);
            save([fn '.segment'],'mask');
        else
            display('Cells have already been segmented --> Skip');
        end
    catch
        display('Error while segmenting...');
    end
    
    
    % Pull signals
    
    try
        clear info global;  % force a new read...
        
        if(~exist([fn '.signals'],'file'))
            display('Extracting signals... ');
            sig = sbxpullsignals(fn);
            save([fn, '.signals'],'sig');
        else
            display('Signals have already been extracted --> Skip');
            
        end
    catch
        display('Error while extracting signals...');
    end
    
elseif(isstr(fn) && exist(fn,'dir'))        % is it a directory?
    
    d = dir([fn '\*.sbx']);
    clear f;
    
    for(i=1:length(d))
        f{i} = strtok(d(i).name,'.');
    end
    
    cd (fn);                               % go into dir...
    sbxprocess(f);                          % process all the files in this directory
    cd('..');                               % come up again...
    
elseif iscellstr(fn)
    
    for(i=1:length(fn))
        sbxprocess(fn{i});
    end
    
else
    
    error('Input must be a string or cell array of strings');
    
end
