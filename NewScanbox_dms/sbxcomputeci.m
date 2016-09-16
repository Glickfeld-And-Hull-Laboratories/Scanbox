function [] = sbxcomputeci(fname)
    vals = load([fname '.align'],'-mat','T','v','Q','thestd');
    T = vals.T;
    Q = vals.Q;
    s = sqrt(vals.v);
    thestd = vals.thestd;
    
    sbxread(fname,0,1);
    global info
    
    %Compute sum, sum of squares
    
    try
    imsize = [info.recordsPerBuffer,size(info.S,2)];
    catch
        imsize = [info.recordsPerBuffer,size(sparseint,2)];
    end
    nframes = info.max_idx;

    %mean, standard deviation    
    %compute correlation coefficient with respect to 3x3 window
    winsize = 35;
    res = .5;
    

    p = gcp();
    nblocks = p.NumWorkers;
    
    xray = zeros([imsize*res,winsize,winsize,nblocks],'double');
    c = zeros(imsize(1),imsize(2),2,nblocks);
        
    maxidx = info.max_idx;
    parfor ii = 1:nblocks
        rg = floor((ii-1)*maxidx/nblocks)+1:floor(ii*maxidx/nblocks);
        [c(:,:,:,ii),xray(:,:,:,:,ii)] = doOneBlock(fname,imsize,res,winsize,T,Q,s,nframes,rg,thestd);
    end
    c = sum(c,4);
    xray = sum(xray,5);

    c3 = (c(:,:,2)-c(:,:,1))/8/nframes;
    xray = single(xray/nframes/2);
    xray = int16(xray*2^15);
    
    save([fname '.align'],'-mat','c3','xray','-append');
    
end

function [c,xray] = doOneBlock(fname,imsize,res,winsize,T,Q,s,nframes,rg,thestd)
    xray = zeros([imsize*res,winsize,winsize],'double');
    c = zeros(imsize(1),imsize(2),2);

    Am = zeros([imsize*res,winsize,winsize],'double');
    Ar2 = 0;
    
    
    for nn = rg
        A = double(sbxreadpacked(fname,nn-1,1));
        A = A./thestd;
        Ar = circshift(A,T(nn,:));
        Ar = reshape(Ar(:) - Q*(Q'*Ar(:)),size(Ar));
        Ar = Ar./s;

        c(:,:,1) = c(:,:,1) + Ar.^2;
        c(:,:,2) = c(:,:,2) + conv2(ones(3,1),ones(1,3),Ar,'same').*Ar;
        
        %Ar = imresize(Ar,res);
        Ar = conv2([.5,1,.5],[.5,1,.5],Ar,'same')/4;
        Ar = Ar(2:2:end,2:2:end);
        Ar2 = Ar2 + Ar;
        if mod(nn,2)==0
            %At low temporal res
            Ar = Ar2;
            for ii = 1:winsize
                for jj = 1:winsize
                    Am(:,:,ii,jj) = Ar.*circshift(Ar,[-(ii-ceil(winsize/2)),-(jj-ceil(winsize/2))]);
                end
            end

            xray = xray + Am;
            Ar2 = 0;
        end

        if mod(nn,100)==0
            fprintf('Pass 2, #%d/%d\n',nn,nframes);
        end
    end
end