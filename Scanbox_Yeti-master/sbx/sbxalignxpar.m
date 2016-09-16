function [m,T] = sbxalignxpar(fname,idx)

if(length(idx)==1)
    A = sbxread(fname,idx(1),1);
    A = squeeze(A);
    m = A;
    T = [0 0];
elseif (length(idx)==2)
    A = sbxread(fname,idx(1),1);
    B = sbxread(fname,idx(2),1);
    A = squeeze(A);
    B = squeeze(B);
    
    [u v] = fftalign(A,B);
    
    Ar = circshift(A,[u,v]);
    m = (Ar+B)/2;
    T = [[u v] ; [0 0]];
else
    
    idx0 = idx(1:floor(end/2));
    idx1 = idx(floor(end/2)+1 : end);
    
    idxp = {idx0,idx1};
    A = cell(1,2);
    T = cell(1,2);
    
    parfor(m=1:2)
        [A{m},T{m}] = sbxalignxpar(fname,idxp{m});        
    end
    
    [u v] = fftalign(A{1},A{2});
     
    Ar = circshift(A{1},[u, v]);
    m = (Ar+A{2})/2;
    T = [(ones(size(T{1},1),1)*[u v] + T{1}) ; T{2}];
end

% 
% function [u,v] = fftalign(A,B)
% 
% N = min(size(A));
% A = A(round(size(A,1)/2)-N/2 + 1 : round(size(A,1)/2)+ N/2, round(size(A,2)/2)-N/2 + 1 : round(size(A,2)/2)+ N/2 );
% B = B(round(size(A,1)/2)-N/2 + 1 : round(size(A,1)/2)+ N/2, round(size(B,2)/2)-N/2 + 1 : round(size(B,2)/2)+ N/2 );
% 
% C = fftshift(real(ifft2(fft2(A).*fft2(rot90(B,2)))));
% [ii,jj] = find(C==max(C(:)));
% u = N/2-ii;
% v = N/2-jj;
% 
