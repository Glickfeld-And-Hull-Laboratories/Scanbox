function log = sbxreadhartleylog(fname)

fid = fopen(fname,'r');
l = fgetl(fid);
k=0;

log = {};
while(l~=-1)
    k = str2num(l(2:end));
    log{k+1} = [];
    e = [];
    l = fgetl(fid);
    while(l~=-1 & l(1)~='T')
        e = [e ; str2num(l)];
        l = fgetl(fid);
    end
    log{k+1} = e;
end

    