function sbxalignmaster(fname)
    global info
    sbxpacksignals(fname); %Takes about 10 minutes
    global info
    %%
    z = sbxreadpacked(fname,0,1);
    szz = size(z);
    
    %Computing first order stats
    fprintf('Getting first-order stats\n');
    
    ms = 0;
    vs = 0;
    
    X = [ones(info.max_idx,1),linspace(-1,1,info.max_idx)'];
    X = bsxfun(@times,X,1./sqrt(sum(X.^2)));
    
    parfor jj = 1:info.max_idx
        z = double(sbxreadpacked(fname,jj-1,1));

        ms = ms + z(:)*X(jj,:);
        vs = vs + z(:).^2;
    end
    
    s = reshape(sqrt(1/info.max_idx*(vs - sum(ms.^2,2))),szz);
    thestd = medfilt2(s,[31,31],'symmetric');
    
    gl = X(:,2);
    l  = reshape(ms(:,2),szz);

    %%
    
    fprintf('Alignment first pass\n');
    
    [m,~,T] = sbxalignpar(fname,thestd,gl,l); %Takes about 2.5 minutes

    rgx = (1:size(m,2))+45;
    rgy = 32 + (1:size(m,1));
    T0 = T;
    
    for nn = 1:10
        fprintf('Refining alignment... pass %d\n',nn);
        [m,~,T] = sbxaligniterative(fname,m,rgy,rgx,thestd(rgy,rgx),gl,l);
        dT = sqrt(mean(sum((T0-T).^2,2)));
        T0 = T;
        if dT < .25
            break;
        end
        fprintf('delta: %.3f\n',dT);
    end

    fprintf('Getting aligned first-order stats\n');
    
    ms = 0;
    vs = 0;
    
    m2 = 0;
    v2 = 0;
    
    X = [ones(info.max_idx,1),linspace(-1,1,info.max_idx)'];
    X = bsxfun(@times,X,1./sqrt(sum(X.^2)));
    
    g = exp(-(-5:5).^2/2/1.6^2);
    tic;
    parfor jj = 1:info.max_idx
        z = single(sbxreadpacked(fname,jj-1,1));
        z = z./thestd;
        z = circshift(z,T(jj,:));
        z = double(z);

        ms = ms + z(:)*X(jj,:);
        vs = vs + z(:).^2;
        
        z = conv2(g,g,z,'same');
        m2 = m2 + z(:)*X(jj,:);
        v2 = v2 + z(:).^2;
    end
    toc;
    
    ss = sqrt(1/info.max_idx*(vs - sum(ms.^2,2)));
    m = reshape(ms(:,1)*X(1,1),size(l));
    v = reshape(ss.^2,size(l));
    
    
    [Q,~] = qr(ms,0);
    [Q2,~] = qr(m2,0);
    s2 = reshape(sqrt(1/info.max_idx*(v2 - sum(m2.^2,2))),size(l));
    m2 = reshape(m2(:,1)*X(1,1),size(l));

    
    %In two passes, compute m, stdx, stdy
    %{
    m0 = 0;
    v0 = 0;
    
    m1 = 0;
    v1 = 0;
    
    g = exp(-(-5:5).^2/2/1.6^2);
    
    fprintf('Computing simple stats... pass %d\n',1);
    parfor jj = 1:info.max_idx
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
    %}
    
    k = 0;
    fprintf('Computing simple stats... pass %d\n',2);
    parfor jj = 1:info.max_idx
        z = double(sbxreadpacked(fname,jj-1,1));
        z = z - gl(jj)*l;
        z = circshift(z,T(jj,:));
        z = z./thestd;
        
        z = conv2(g,g,z,'same');
        z = reshape(z(:) - (Q2*(Q2'*z(:))),size(z));
        k  =  k + (z./s2).^4;
    end
    
    sm = s2./m2;
    k = k/info.max_idx - 3;
    
    try
        save([fname '.align'],'m','v','thestd','sm','k','T','Q','-append');
    catch
        save([fname '.align'],'m','v','thestd','sm','k','T','Q');
    end
    
    % Commented out by dms, 11/2/2015
    tic;
    cd(fname(1:end-11))%added by amw to fix directory issue...
    fstr = fname(end-10:end);
    sbxcomputeci(fstr); %Takes about 10 minutes, eats up a ton of RAM
    toc;
end