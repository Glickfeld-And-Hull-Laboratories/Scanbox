function [mu,v] = sbxzscore(fname,idx)

global info;

S = sparseint;

if(length(idx)==1)

    z = sbxread(fname,idx(1),1);
    z = squeeze(z(1,:,:))*S;
    mu = z;
    v = zeros(size(mu));
else
    z = sbxread(fname,idx(1),1);
    z = squeeze(z(1,:,:))*S;
    z = circshift(z,info.aligned.T(idx(1)+1)); % alignment

    [mu0,v0] = sbxzscore(fname,idx(2:end));
    
    mu = mu0 + (z-mu0)/length(idx);
    m02 = mu0.^2;
    v = v0 + m02 - mu.^2 + (z.^2 - v0 - m02)/length(idx);
end



