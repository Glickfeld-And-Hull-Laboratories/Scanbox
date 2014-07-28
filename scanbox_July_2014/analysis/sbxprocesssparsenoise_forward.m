
function r = sbxprocesssparsenoise_forward(fn)

global info;

z = sbxread(fn,0,1);

load(fn);

lag = -20:30;
minl = lag(1);
maxl = lag(end);


f = info.frame+info.line/512;
f = f(2:end);
t = 0:60:60*(length(f)-1);
t = t';
p = polyfit(t,f,1);

load([fn '.signals'],'-mat')

% fix NaNs
idx = find(isnan(sum(sig)));
sig(:,idx)=0;

%spk = sbxextractspikes(sig);
spk = zscore(sig);

log = load([fn '.log_02']);
log(:,end+1) = log(:,1)-log(:,end);

rf = zeros(size(sig,2),1200/4,2000/4,length(lag),2);
B = zeros(1200/4,2000/4);
D = zeros(size(B));
for(j=1:size(log,1))
    ton = round(polyval(p,log(j,end)));   % onset of this dot in frames
    ii = round((log(j,3)+600)/4);
    jj = round((log(j,2)+1000)/4);
    if(log(j,4)==0) 
        rf(:,ii,jj,:,1) = squeeze(rf(:,ii,jj,:,1)) + spk(ton+minl:ton+maxl,:)' ;
        D(ii,jj) = D(ii,jj)+1;
    else
        rf(:,ii,jj,:,2) = squeeze(rf(:,ii,jj,:,2)) + spk(ton+minl:ton+maxl,:)' ;
        B(ii,jj) = B(ii,jj)+1;
    end
end

% process and save good RFs...

H = fspecial('gaussian',50,10);

Bf = filter2(H,B,'same');
Df = filter2(H,D,'same');

T = find(lag<=0);

h = waitbar(0,'Please wait...');

for(j=1:size(sig,2))
    waitbar(j/size(sig,2),h);
    for(zz=1:length(lag))
        rf(j,:,:,zz,2)=filter2(H,squeeze(rf(j,:,:,zz,2)),'same'); 
        rf(j,:,:,zz,1)=filter2(H,squeeze(rf(j,:,:,zz,1)),'same');
    end
    
    Md = squeeze(mean(rf(j,:,:,T,1),4));
    Mb = squeeze(mean(rf(j,:,:,T,2),4));
    Sd = squeeze(std(rf(j,:,:,T,1),[],4));
    Sb = squeeze(std(rf(j,:,:,T,2),[],4));
    
    for(zz=1:length(lag))
        rf(j,:,:,zz,2)= (squeeze(rf(j,:,:,zz,2))-Mb)./Sb;
        rf(j,:,:,zz,1)= (squeeze(rf(j,:,:,zz,1))-Md)./Sd;
    end
    
    r = squeeze(rf(j,:,:,:,:));

    save([ 'sparse/' fn sprintf('_%03d',j) '_rf'],'r','lag','Bf','Df','-v7.3');
    
end

delete(h);


