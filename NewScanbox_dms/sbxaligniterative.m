function [m,v,T] = sbxaligniterative(fname,m0,rg1,rg2,thestd,gl,l)

% Aligns images in fname for all indices in idx
% 
% m - mean image after the alignment
% T - optimal translation for each frame

global info
T = zeros(info.max_idx,2);
A = sbxreadpacked(fname,0,1);
m = zeros(length(rg1),length(rg2));
v = zeros(length(rg1),length(rg2));

l = l(rg1,rg2);

max_idx = info.max_idx;

parfor ii = 1:max_idx
    A = sbxreadpacked(fname,ii-1,1);
    A = double(A(rg1,rg2));
    A = A - gl(ii)*l;
    A = A./thestd;
    [dx,dy] = fftalign(A,m0);
    T(ii,:) = [dx,dy];
    
    Ar = circshift(A,[dx, dy]);
    m = m+double(Ar);
    
    Ar = circshift(A.^2,[dx, dy]);
    v = v + double(Ar);

end

m = m/max_idx;
v = m/max_idx;