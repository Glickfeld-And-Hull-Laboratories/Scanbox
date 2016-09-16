theday = 'C:\DATA\dms\m074\m074_20160615';
if ispc,
    slash = '\';
else
    slash = '/';
end

%%
%List all the experiments
cases = dir([theday,slash,'*.sbx']);
fnames = {};
for ii =1:length(cases)
    fnames{ii} = [theday, slash, cases(ii).name(1:end-4)];
end

%%
%Add in new scanbox version flag
for ii = 1:length(fnames)
    load(fnames{ii});
    info.scanbox_version = 2;
    clear d 
    d.info = info;
    save(fnames{ii},'-struct','d');
end

%%
%Print in console
for ii = 1:length(cases)
    fprintf('%02d. %s\n',ii,fnames{ii});
end


%%
for ii = 1:length(cases) % or use ii = x
    %xray
    
    sbxalignmaster(fnames{ii});
     
    
    
    %gamma ray
    %sbxalignprecise(fnames{ii});
end

%%cases
%sbxpullsignalspacked('C:/2PDATA/xx0/2/xx0_002_001');