function wbmcb(src,callbackdata)

global img0_h gData gtime me va ku corrmap th_corr th_txt
global ncell cellpoly alist_h;

p = gca;
z = round(p.CurrentPoint);
z = z(1,1:2);
if(z(1)>0 && z(2)>0 && z(1)<796 && z(2)<512)
    bw = img0_h.CData(:,:,3);
    B = bwboundaries(bw);
    xy = B{1};
    hold(img0_h.Parent,'on');
    h = patch(xy(:,2),xy(:,1),'white','facecolor',[1 .7 .7],'facealpha',0.7,'edgecolor',[1 0 0],'parent',img0_h.Parent,'FaceLighting','none');
      
    l = get(alist_h,'String');
    if(isempty(l))
        ncell = ncell+1;
        l = {num2str(ncell)};
        cellpoly{ncell} = h;
    else
        ncell = ncell+1;
        l = {l{:} num2str(ncell)};
        cellpoly{ncell} = h;
    end
    set(alist_h,'String',l,'Value',length(l));
 
    hold(img0_h.Parent,'off');
end

