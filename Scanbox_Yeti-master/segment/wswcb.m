function wswcb(src,callbackdata)

% scroll wheel callback

global img0_h gData gtime me va ku corrmap th_corr th_txt

th_corr = th_corr-callbackdata.VerticalScrollCount/50;
th_corr = min(max(th_corr,0),1);
th_txt.String = sprintf('%1.2f',th_corr);
    
p = gca;
z = round(p.CurrentPoint);
z = z(1,1:2);
if(z(1)>0 && z(2)>0 && z(1)<796 && z(2)<512)
    cm = squeeze(sum(bsxfun(@times,gData(1:gtime,z(2),z(1)),gData(1:gtime,:,:)),1))/gtime;
    img0_h.CData(:,:,2) = uint8(255*gather(cm>th_corr));
end
