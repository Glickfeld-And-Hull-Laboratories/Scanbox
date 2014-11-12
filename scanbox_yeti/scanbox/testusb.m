s = serial('COM3','BytesAvailableFcn',@serialcb, ...
    'BytesAvailableFcnMode','byte', ...
    'InputBufferSize',10000, ...
    'OutputBufferSize',10000, ...
    'BytesAvailableFcnCount',5);

fopen(s)

global T;
T = uint8([]);

fwrite(s,uint8([1 1 0]));
fwrite(s,uint8([2 1 0]));
fwrite(s,uint8([3 0 0])); % magnification 

fwrite(s,uint8([4 0 1])); % run...

fclose(s)


ts = zeros(size(T,1),1,'uint32');
for(i=0:3)
    ts = ts+ uint32(T(:,i+1))*(256^i);
end
ts = intmax('uint32')-ts;

plot(ts,'-o'),figure(gcf)

1/median(diff(double(ts)))*1e6



t1 = ts(find(bitand(T(:,5),uint8(1))))
t2 = ts(find(bitand(T(:,5),uint8(2)))) 