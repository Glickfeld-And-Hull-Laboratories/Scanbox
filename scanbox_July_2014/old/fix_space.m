
% Test spatial correction...

p = 1250; % period of sampling grating.
t = 0:1023; % actual line size

xpos = -cos(t*pi/p); % actual position

% tavg = mean(diff(xpos));
% xi = (pi  -(acos(xpos(1):tavg:xpos(end))))*p/pi; % times at which I want to interpolate
% xi = xi(1:length(t));

m = max(diff(xpos));
L = xpos(1):m:xpos(end);

xi = (pi  -(acos(L)))*p/pi; % times at which I want to interpolate

nsamp = length(xi);

ri = zeros(size(r,1),nsamp); % r is the image

% interpolant matrix

S = sparse(nsamp,1024,0);
for(i=1:nsamp)
    [d,idx] = sort(abs(xi(i)-t));
    ii = idx(1);
    jj = idx(2);
    wi = d(2)/(d(1)+d(2));
    wj = d(1)/(d(1)+d(2));
    S(i,ii) = wi;
    S(i,jj) = wj;
end
S = S';

% actual interpolation
tic,ri = r*S; toc