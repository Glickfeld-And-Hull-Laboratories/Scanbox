function sbxautocalbd(mag)

% Auto-calibrate bi-directional scanning

global scanbox_h sbconfig

q = findobj(scanbox_h,'tag','frames');
q.String = '100';
q.Callback(q,[]);

t = findobj(scanbox_h,'tag','tfilter');
t.Value = 3;
t.Callback(t,[]);

g = findobj(scanbox_h,'tag','grabb');
m = findobj(scanbox_h,'tag','magnification');

m.Value = mag;
m.Callback(m,[]);

xorg = sbconfig.ncolbi(mag);    % initial guess

xl = round(xorg-40);
xh = round(xorg+40);

try
    
display('Auto-calibrating...');

yl = Edelta(g,mag,xl);
display(sprintf('low :(%4d,%4d)',xl,yl))
yh = Edelta(g,mag,xh);
display(sprintf('high:(%4d,%4d)',xh,yh))

if(sign(yl*yh)<0)
    while((xh-xl)>1)
        display(sprintf('low=(%4d,%4d) high=(%4d,%4d)',xl,yl,xh,yh))
        xm = round((xl+xh)/2);
        ym = Edelta(g,mag,xm);
        if(sign(ym*yh)<0)
            xl = xm;
            yl = ym;
        else
            xh = xm;
            yh = ym;
        end
    end
else
    display('Endpoints do not bracket optima setting');
end

if(yl<yh)
    display(sprintf('Optimal value: %4d',xl));
else
    display(sprintf('Optimal value: %4d',xh));
end
    
sbconfig.ncolbi(mag) = xorg;

catch
    sbconfig.ncolbi(mag) = xorg; 
end

function u = Edelta(g,mag,val)

global accd sbconfig;

sbconfig.ncolbi(mag) = val;

g.Callback(g,[])
z = accd;
z = diff(z);
ze = z(:,2:2:end);
zo = z(:,1:2:end-1);
[u,v] = fftalign(ze,zo);








