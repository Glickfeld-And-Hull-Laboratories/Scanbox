
function wbm(varargin)
global scanbox_h

p = round(get(gca,'CurrentPoint'));
p = p(1,1:2);
if(p(2)>= 0 && p(2)<=512 && p(1)>0 && p(1)<=796)
    set(scanbox_h,'Pointer','crosshair');
else
    set(scanbox_h,'Pointer','arrow');
end