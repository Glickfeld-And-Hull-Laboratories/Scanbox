function [m,mu,T] = sbxalign(fname,idx,row,col)

[opt,met] = imregconfig('monomodal');

if(length(idx)==1)
    A = sbxread(fname,idx(1),1);
    S = sparseint;
    A = squeeze(A(1,:,:))*S;
    m = A;
    mu = A;
    T = {eye(3)};
elseif (length(idx)==2)
    A = sbxread(fname,idx(1),1);
    B = sbxread(fname,idx(2),1);
    S = sparseint;
    A = squeeze(A(1,:,:))*S;
    B = squeeze(B(1,:,:))*S;
    if(isempty(row))
        tform = imregtform(A,B,'translation',opt,met);
    else
        tform = imregtform(A(row,col),B(row,col),'translation',opt,met);
    end
    Ar = imwarp(A,tform,'OutputView',imref2d(size(A)));
    m = (Ar+B)/2;
    mu = (A+B);
    T = {tform.T  eye(3)};
else
    idx0 = idx(1:floor(end/2));
    idx1 = idx(floor(end/2)+1 : end);
    [A,acc0,T0] = sbxalign(fname,idx0,row,col);
    [B,acc1,T1] = sbxalign(fname,idx1,row,col);
    if(isempty(row))
        tform = imregtform(A,B,'translation',opt,met);
    else
        tform = imregtform(A(row,col),B(row,col),'translation',opt,met);
    end
    Ar = imwarp(A,tform,'OutputView',imref2d(size(A)));
    m = (Ar+B)/2;
    mu = (acc0+acc1);
    for(i=1:length(T0))
        T0{i} = tform.T * T0{i};
    end
    T = {T0{:} T1{:}};
end
