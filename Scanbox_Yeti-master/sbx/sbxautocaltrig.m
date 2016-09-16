function sbxautocaltrig

% Auto-calibrate trigger level

global scanbox_h sbconfig boardHandle

q = findobj(scanbox_h,'tag','frames');
q.String = '100';
q.Callback(q,[]);

t = findobj(scanbox_h,'tag','tfilter');
t.Value = 3;
t.Callback(t,[]);

g = findobj(scanbox_h,'tag','grabb');

L=16:16:192
        
display('Auto-calibrating...');

y = zeros(1,length(L));

for(j=1:length(L))
    y(j) = Edelta(g,L(j));
end

plot(L,y,'-o')


function u = Edelta(g,val)

global accd scanbox_h sbconfig boardHandle

AlazarDefs

retCode = ...
    calllib('ATSApi', 'AlazarSetTriggerOperation', ...
    boardHandle,		...	% HANDLE -- board handle
    TRIG_ENGINE_OP_J,	...	% U32 -- trigger operation
    TRIG_ENGINE_J,		...	% U32 -- trigger engine id
    TRIG_EXTERNAL,		...	% U32 -- trigger with TRIGOUT
    TRIGGER_SLOPE_POSITIVE+sbconfig.trig_slope,	... % U32 -- THE HSYNC is flipped on the PSoC board...
    val, ...	% U32 -- trigger level from 0 (-range) to 255 (+range) 
    TRIG_ENGINE_K,		...	% U32 -- trigger engine id
    TRIG_DISABLE,		...	% U32 -- trigger source id for engine K
    TRIGGER_SLOPE_POSITIVE, ...	% U32 -- trigger slope id
    128					...	% U32 -- trigger level from 0 (-range) to 255 (+range)
    );

g.Callback(g,[])
z = accd;
if(isempty(z))
    u = NaN;
else 
u = median(z(:));
end





