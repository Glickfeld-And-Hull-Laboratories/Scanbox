
function S = sparseint;

p = 1250;       % period of sampling grating.
t = 0:(p-1);    % line size

xpos = -cos(t*pi/p);    % actual position of beam
m = max(diff(xpos));    % isotropic at the center
L = xpos(1):m:xpos(end);

xi = (pi  -(acos(L)))*p/pi; % times at which we want to interpolate

nsamp = length(xi);

ri = zeros(p,nsamp); % r is the image

% Calculate sparse interpolant matrix
% Simple linear interpolation of nearest pixels for now
% Can be changed for fancier interpoaltion later...

S = sparse(nsamp,p,0);

for(i=1:nsamp)
    [d,idx] = sort(abs(xi(i)-t));
    
    S(i,idx(1))=1;
    
%     ii = idx(1); jj = idx(2);
%     wi = d(2)/(d(1)+d(2));
%     wj = d(1)/(d(1)+d(2));
%     S(i,ii) = wi;
%     S(i,jj) = wj;
end

S = S';
