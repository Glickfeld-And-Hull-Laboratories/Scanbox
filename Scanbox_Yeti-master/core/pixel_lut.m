
function S = pixel_lut;

p = 1250;       % period of sampling grating.
t = 0:(p-1);    % line size

xpos = -cos(t*pi/p);    % actual position of beam
m = max(diff(xpos));    % isotropic at the center
L = xpos(1):m:xpos(end);

xi = (pi  -(acos(L)))*p/pi; % times at which we want to interpolate

nsamp = length(xi);

ri = zeros(p,nsamp); % r is the image

S = zeros(1,nsamp);

for(i=1:nsamp)
    [~,idx] = min(abs(xi(i)-t));    
    S(i) = idx;
end

