function r = sbxmatchfields(fn1,fn2,fn3,th)

try
    m1 = load([fn1 '.segment'],'mask','-mat'); m1 = m1.mask;
    m2 = load([fn2 '.segment'],'mask','-mat'); m2 = m2.mask;
    m3 = load([fn3 '.segment'],'mask','-mat'); m3 = m3.mask;
catch
    error('You must segment first...')
end

m12 = sbxmatchfields(fn1,fn2,th); drawnow;
m23 = sbxmatchfields(fn2,fn3,th); drawnow;
m31 = sbxmatchfields(fn3,fn1,th); drawnow;

L = [];
for(i=3:size(m12.match,1))
    j = find(m12.match(i,2)==m23.match(:,1));
    if(~isempty(j))
        k = find(m23.match(j,2)==m31.match(:,1));
        if(~isempty(k))
            if(m31.match(k,2)==m12.match(i,1))
                L = [L; m12.match(i,1) m23.match(j,1) m31.match(k,1)];
            end
        end
    end
end

[u,v] = fftalign(m1~=0,m2~=0);
m1 = circshift(m1,[u v]);

[u,v] = fftalign(m3~=0,m2~=0);
m3 = circshift(m3,[u v]);

z = zeros([size(m1),3]);
z(:,:,1) = ismember(m1,L(:,1));
z(:,:,2) = ismember(m2,L(:,2));
z(:,:,3) = ismember(m3,L(:,3));

imshow(z);

r.match = L;
