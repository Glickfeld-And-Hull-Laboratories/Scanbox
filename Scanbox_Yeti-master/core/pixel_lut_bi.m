function [S,pIdx,pIdxA,cdIdx,ncol] = pixel_lut_bi(nlines,ncolbi)

p = ncolbi;                        % half period of sampling grating.
pr = (9000-ncolbi*4)/4;            % samples on the return
t = 0:(p-1);       % line size
th = t/p*pi;

xpos = -cos(th);        % actual position of beam
m = max(diff(xpos));    % isotropic at the center
L = -1:m:1;
Lr = L(end:-1:1);
ncol = length(L);

xi = (pi  -(acos(L))) *p/pi; % times at which we want to interpolate
idx = find(xi<=pr, 1, 'last' );
xi = [xi p + xi(1:idx)];

nsamp = length(xi);

ri = zeros(p,nsamp); % r is the image

S = zeros(1,nsamp);
t = [t ncolbi+(0:pr-1)];
for(i=1:nsamp)
    [~,idx] = min(abs(xi(i)-t));
    S(i) = idx;
end

sz = [2 ncol nlines];
postIdx = reshape(0:prod(sz)-1,sz);
postIdx(:,:,2:2:end) = postIdx(:,end:-1:1,2:2:end);   % reverse even rows
skip = 2*ncol-length(S);                               % pixels to skip
postIdx(:,1:skip,2:2:end) = NaN;
% postIdx(:,:,2:2:end) = circshift(postIdx(:,:,2:2:end),[0 dx 0]);
[z,j] = sort(postIdx(:));
j = j(~isnan(z));
pIdx = j-1;

sz = [1 ncol nlines];
postIdx = reshape(0:prod(sz)-1,sz);
postIdx(:,:,2:2:end) = postIdx(:,end:-1:1,2:2:end);   % reverse even rows
skip = 2*ncol-length(S);                               % pixels to skip
postIdx(:,1:skip,2:2:end) = NaN;
% postIdx(:,:,2:2:end) = circshift(postIdx(:,:,2:2:end),[0 dx 0]);
[z,j] = sort(postIdx(:));
j = j(~isnan(z));
pIdxA = j-1;

sz = [3 ncol nlines];
postIdx = reshape(0:prod(sz)-1,sz);
postIdx(:,:,2:2:end) = postIdx(:,end:-1:1,2:2:end);   % reverse even rows
skip = 2*ncol-length(S);                               % pixels to skip
postIdx(:,1:skip,2:2:end) = NaN;
% postIdx(:,:,2:2:end) = circshift(postIdx(:,:,2:2:end),[0 dx 0]);
[z,j] = sort(postIdx(:));
j = j(~isnan(z));
cdIdx = j-1;

pIdx =  uint32(pIdx);
pIdxA = uint32(pIdxA);
cdIdx = uint32(cdIdx);



