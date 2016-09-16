function wbmcb(src,callbackdata)

global img0_h gData gtime me va ku corrmap th_corr th_txt

p = gca;
z = round(p.CurrentPoint);
z = z(1,1:2);
if(z(1)>0 && z(2)>0 && z(1)<796 && z(2)<512)
    cm = squeeze(sum(bsxfun(@times,gData(1:gtime,z(2),z(1)),gData(1:gtime,:,:)),1))/gtime;
    imgth = gather(cm>th_corr);
    img0_h.CData(:,:,2) = uint8(255*imgth);
    global D;
    D = bwdistgeodesic(imgth,z(1,1),z(1,2));
    bw = imdilate(isfinite(D),strel('disk',1));
    img0_h.CData(:,:,3) = uint8(255*bw); 
end