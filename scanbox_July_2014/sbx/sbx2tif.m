function sbx2tif(fname)

q = read_sbx(fname,1,1); q = squeeze(q(:,:,1));
k = 1;
done = 0;
while(~done)
    try
        q = read_sbx(fname,k,1);
        q = squeeze(q(:,:,1));
        q = uint8(255*(q+double(intmax('uint16')))/double(intmax('uint16')));
        imwrite(q,[fname '.tif'],'tif','writemode','append');
        
    catch
        done = 1;
    end
    k = k+1
end