function sb_axis_gain(ax,x,mult)

global sb;

% ax = 1 -> x axis
% ax = 0 -> y axis 

% x = 0, 1 ,2 (x1, x2 ,x4)


if(ax)
    code = hex2dec('f0')+x;
else
    code = x;
end

m = round((mult-1)*128+128);

fwrite(sb,uint8([51 code m]));