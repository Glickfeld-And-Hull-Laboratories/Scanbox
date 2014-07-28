function r = sbxsym(img)

% evaluate symmetry of img around this point


z = zeros(size(img));
for(i=0:3)
    z = z+rot90(img,i);
end

r = corrcoef(img(:),z(:));
r = r(1,2);
