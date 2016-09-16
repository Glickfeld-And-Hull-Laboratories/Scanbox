function ephysdata(src,event)
global efid;
fwrite(efid,event.Data','single');
end
