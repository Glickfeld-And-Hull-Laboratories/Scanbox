function sbxalignprecise(fname)
    global info
    tic;
    sbxpacksignals(fname); %Takes about 10 minutes
    toc;
    %%
    z = sbxreadpacked(fname,0,1);
    szz = size(z);
    
    %Computing first order stats
    fprintf('Getting first-order stats\n');
    
    ms = 0;
    vs = 0;
    
    X = [ones(info.max_idx,1),linspace(-1,1,info.max_idx)'];
    X = bsxfun(@times,X,1./sqrt(sum(X.^2)));
    
    tic;
    parfor jj = 1:info.max_idx
        z = double(sbxreadpacked(fname,jj-1,1));

        ms = ms + z(:)*X(jj,:);
        vs = vs + z(:).^2;
    end
    toc;
    
    s = reshape(sqrt(1/info.max_idx*(vs - sum(ms.^2,2))),szz);
    thestd = medfilt2(s,[31,31],'symmetric');
    
    gl = X(:,2);
    l  = reshape(ms(:,2),szz);
    
    %%
    fprintf('Alignment first pass\n');
    tic;
    [m,~,T] = sbxalignpar(fname,thestd,gl,l); %Takes about 2.5 minutes
    toc;
    rgx = (1:size(m,2))+45;
    rgy = 32 + (1:size(m,1));
    T0 = T;
    
    T_ = T;
    
    m0 = m;
    T = bsxfun(@minus,T,median(T));
    for nn = 1:10
        fprintf('Refining alignment... pass %d\n',nn);
        tic;
        %[m,~,T] = sbxaligniterative(fname,m,rgy,rgx,thestd(rgy,rgx),gl,l);
        [m,~,T] = sbxalignrobust(fname,m,rgy,rgx,thestd(rgy,rgx),gl,l,T0);
        T = bsxfun(@minus,T,median(T));
        toc;
        dT = sqrt(mean(sum((T0-T).^2,2)));
        if dT < .25
            break;
        end
        fprintf('delta: %.3f\n',dT);
        T0 = T;
    end
    
    fprintf('Getting aligned first-order stats\n');
    
    ms = 0;
    vs = 0;
    
    X = [ones(info.max_idx,1),linspace(-1,1,info.max_idx)'];
    X = bsxfun(@times,X,1./sqrt(sum(X.^2)));
    
    tic;
    parfor jj = 1:info.max_idx
        z = single(sbxreadpacked(fname,jj-1,1));
        z = z./thestd;
        z = circshift(z,T(jj,:));

        %Dx = (B*dx(:,jj))*ones(1,size(z,2));
        %Dy = (B*dy(:,jj))*ones(1,size(z,2));

        %z = interp2(z,xi+Dx,yi+Dy);
        z = double(z);
        z(isnan(z)) = nanmedian(z(:));

        ms = ms + z(:)*X(jj,:);
        vs = vs + z(:).^2;
    end
    toc;
    
    ss = sqrt(1/info.max_idx*(vs - sum(ms.^2,2)));

    MM = [ms,ss];
    MM = bsxfun(@times,MM,1./std(MM));
    [Q,~] = qr(MM,0);

    %%
    %save([fname '.align'],'-append','m','thestd','T');
    %Force a refresh of the alignment
    %global info_loaded
    %info_loaded = '';
    
    %Do non-rigid alignment
    fprintf('Non-rigid alignment\n');
    tic;
    [dx,dy] = sbxnonrigidalignprecise(fname,T,Q,thestd);
    toc;
    %%
    fprintf('Getting non-rigid aligned first-order stats\n');
    
    [~,~,~,B] = doLucasKanade(m(1:end-16,:),m(1:end-16,:));
    B = [ones(32,1)*B(1,:);B;ones(16,1)*B(end,:)];
    [xi,yi] = meshgrid(1:size(l,2),1:size(l,1));

    ms = 0;
    vs = 0;
    
    tic;
    parfor jj = 1:info.max_idx
        z = single(sbxreadpacked(fname,jj-1,1));
        z = z./thestd;
        z = circshift(z,T(jj,:));

        Dx = (B*dx(:,jj))*ones(1,size(z,2));
        Dy = (B*dy(:,jj))*ones(1,size(z,2));

        z = interp2(z,xi+Dx,yi+Dy);
        z = double(z);
        z(isnan(z)) = nanmedian(z(:));

        ms = ms + z(:)*X(jj,:);
        vs = vs + z(:).^2;
    end
    toc;
    
    ss = reshape(sqrt(1/info.max_idx*(vs - sum(ms.^2,2))),size(thestd));

    MM = [ms];
    MM = bsxfun(@times,MM,1./std(MM));
    [Q,~] = qr(MM,0);
    
    %%
    fprintf('Getting second-order stats\n');

    tic;
    nt = ceil(info.max_idx/5000);
    F = zeros([512-32,796,ceil(info.max_idx/nt)],'single');
    for jj = 1:nt:info.max_idx

        Z = 0;
        nn = 0;
        for ii = 1:nt
            tgt = jj-1+ii-1;
            if tgt > info.max_idx;
                continue
            end
            z = single(sbxreadpacked(fname,jj-1+ii-1,1));
            z = mean(z,3);
            z = z./thestd;
            z = circshift(z,T(jj,:));

            Dx = (B*dx(:,jj))*ones(1,size(z,2));
            Dy = (B*dy(:,jj))*ones(1,size(z,2));

            z = interp2(gpuArray(z),xi+Dx,yi+Dy);
            z = double(gather(z));
            z(isnan(z)) = nanmedian(z(:));
            z = reshape((z(:) - Q*(Q'*z(:))),size(z));
            Z = Z + z(33:end,:);
            nn = nn + 1;
        end
        z = Z/nn;
        szz = size(z);

        F(:,:,ceil(jj/nt)) = single(z);

        if mod(jj-1,100) == 0
            jj
        end
    end
    toc;
    
    %%
    fprintf('PCA\n');
    tic;
    [U,S,~] = svd(reshape(F,size(F,1)*size(F,2),size(F,3)),'econ');

    dS = diag(S);
    x = 1:length(dS);
    x = x(end/4:3*end/4);
    y = dS(end/4:end/4*3);
    w = [x',ones(size(x'))]\y;

    %%
    x = 1:length(dS);
    stopidx = find(dS./(x'*w(1)+w(2))<1.1,1);
    stopidx = min(stopidx,500);
    toc;
    
    %%
    fprintf('Selected %d components\n',stopidx);
    
    %%
    fprintf('Compressing data\n');
    
    tic;
    Vs = zeros(stopidx,info.max_idx);
    Us = U(:,1:stopidx);

    ws = zeros(size(Q,2),info.max_idx);
    
    v = 0;
    c3 = 0;
    k = 0;
    m2 = 0;
    v2 = 0;
    g = exp(-(-5:5).^2/2/1.6^2);
    
    parfor jj = 1:info.max_idx

        z = single(sbxreadpacked(fname,jj-1,1));
        %z = mean(z,3);
        z = z./thestd;
        z = circshift(z,T(jj,:));

        Dx = (B*dx(:,jj))*ones(1,size(z,2));
        Dy = (B*dy(:,jj))*ones(1,size(z,2));

        z = interp2((z),xi+Dx,yi+Dy);
        z = double(gather(z));
        z(isnan(z)) = nanmedian(z(:));
        ws(:,jj) = Q'*z(:);
        
        z2 = conv2(g,g,z,'same');
        m2 = m2 + z2;
        
        z = reshape(z(:) - Q*(Q'*z(:)),size(z));
        
        z2 = conv2(g,g,z,'same');
        v2 = v2 + z2.^2;
        
        
        %correlation image computation
        Z = z./ss;
        c3 = c3 + convn(Z,[1,1,1;1,0,1;1,1,1]/8,'same').*Z;
        
        
        z = z(33:end,:);

        P = Us'*z(:);
        Vs(:,jj) = P;
        
        Pp = (Us*P);
        k = k + Pp.^4;
        v = v + Pp.^2;
        
        if mod(jj,100)==0
            jj
        end
    end
    toc;
    
    %
    fprintf('Finalizing processing\n');
    k = [zeros(32,size(s,2));reshape(info.max_idx*(k./v(:).^2),size(thestd)-[32,0])];
    
    m = reshape(ms(:,1)*X(1,1),size(s));
    v = reshape(ss.^2,size(s));
    m2 = m2/info.max_idx;
    v2 = v2/info.max_idx;
    
    sm = sqrt(v2)./m2;
    c3 = reshape(c3/info.max_idx,size(s));
    
    ss = sqrt(v/info.max_idx);
    
    try
        save([fname '.nonrigid.align'],'m','v','thestd','sm','k','T','c3','ss','dx','dy','Us','Vs','Q','ws','-append');
    catch me
        save([fname '.nonrigid.align'],'m','v','thestd','sm','k','T','c3','ss','dx','dy','Us','Vs','Q','ws');
    end
    %T = T
    %dx = dx, dy = dy
    %Q,w,Us,Vs
    
    %missing ci, k, 
    
    
    
    %%
    
    %{
    %In two passes, compute m, stdx, stdy
    m0 = 0;
    v0 = 0;
    
    m1 = 0;
    v1 = 0;
    
    g = exp(-(-5:5).^2/2/1.6^2);
    
    fprintf('Computing simple stats... pass %d\n',1);
    for jj = 1:info.max_idx
        z = double(sbxreadpacked(fname,jj-1,1));
        z = z - gl(jj)*l;
        z = circshift(z,T(jj,:));
        z = z./thestd;
        
        m0 = m0 + z;
        v0 = v0 + z.^2;

        z = conv2(g,g,z,'same');
        
        m1 = m1 + z;
        v1 = v1 + z.^2;
    end
    
    m = m0/info.max_idx;
    v = v0/info.max_idx;

    m2 = m1/info.max_idx;
    v2 = v1/info.max_idx;

    s2 = sqrt(v2 - m2.^2);

    k = 0;
    fprintf('Computing simple stats... pass %d\n',2);
    for jj = 1:info.max_idx
        z = double(sbxreadpacked(fname,jj-1,1));
        z = z - gl(jj)*l;
        z = circshift(z,T(jj,:));
        z = z./thestd;
        
        z = conv2(g,g,z,'same');
        k  =  k + ((z-m2)./s2).^4;
    end
    
    sm = s2./m2;
    k = k/info.max_idx - 3;
    
    save([fname '.align'],'m','v','thestd','sm','k','T','-append');
    
    tic;
    sbxcomputeci(fname); %Takes about 10 minutes, eats up a ton of RAM
    toc;
    %}
end