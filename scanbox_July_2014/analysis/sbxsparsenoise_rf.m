function y = sbxsparsenoise_rf(r,ncell,radius)

ncell = size(r.rf,1);

r.Bf = filter2(fspecial('gaussian',100,radius),r.B,'valid');
r.Df = filter2(fspecial('gaussian',100,radius),r.B,'valid');
h = fspecial('gaussian',100,radius);


for(c=1:2) % black and white...
    
    for(zz=1:length(r.lag))
        zz
        if(c==1)
            r.rf(ncell,:,:,zz,c)=filter2(h,squeeze(r.rf(ncell,:,:,zz,c)),'same')./r.Df;
        else
            r.rf(ncell,:,:,zz,c)=filter2(h,squeeze(r.rf(ncell,:,:,zz,c)),'same')./r.Bf;
        end
    end
    
    m = mean(squeeze(r.rf(ncell,:,:,[1:10 40:50],c)),3);
    s = std(squeeze(r.rf(ncell,:,:,[1:10 40:50],c)),[],3);
    
    for(zz=1:length(r.lag))
        r.rf(ncell,:,:,zz,c)= (squeeze(r.rf(ncell,:,:,zz,c))-m)./s;
    end
end
