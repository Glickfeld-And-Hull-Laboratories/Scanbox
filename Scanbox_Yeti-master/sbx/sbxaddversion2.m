% add version 2 to all mat files in directory

d = dir('*.mat');
for(i=1:length(d))
    [a,b]=strtok(d(i).name,'.');
    if(double(a(end))>=48 & double(a(end)<=57))
        load(d(i).name);
        info.scanbox_version = 2;
        save(d(i).name,'info');
    end
end
