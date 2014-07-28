function [m,T] = sbxalignx(fname,idx)

if(length(idx)==1)
    
    A = sbxread(fname,idx(1),1);
    S = sparseint;
    A = squeeze(A(1,:,:))*S;
    m = A;
    T = [0 0];
    
elseif (length(idx)==2)
    
    A = sbxread(fname,idx(1),1);
    B = sbxread(fname,idx(2),1);
    S = sparseint;
    A = squeeze(A(1,:,:))*S;
    B = squeeze(B(1,:,:))*S;
    
    [u v] = fftalign(A,B);
    
    Ar = circshift(A,[u,v]);
    m = (Ar+B)/2;
    T = [[u v] ; [0 0]];
    
else
    
    idx0 = idx(1:floor(end/2));
    idx1 = idx(floor(end/2)+1 : end);
    [A,T0] = sbxalignx(fname,idx0);
    [B,T1] = sbxalignx(fname,idx1);
   
    [u v] = fftalign(A,B);
     
    Ar = circshift(A,[u, v]);
    m = (Ar+B)/2;
    T = [(ones(size(T0,1),1)*[u v] + T0) ; T1];
    
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
