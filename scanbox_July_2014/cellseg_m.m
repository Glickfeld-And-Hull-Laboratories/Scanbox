function m = cellseg_m(x)

x = (x - min(x(:)))./(max(x(:))-min(x(:)));

N = (size(x,1)-1)/2;
[xx,yy]=meshgrid(-N:N,-N:N);
r = sqrt(xx.^2+yy.^2);

m=zeros(1,N);
for(i=1:N)
    idx = find(r>i-0.5 & r<i+0.5);
    m(i) = mean(x(idx));
end

b = mean(m(1:4));
th = b+(max(m)-b)*.4;

if(b/max(m)<0.9)
    idx = find(m>th);
    i0 = min(idx);
    i1 = max(idx);
    i1 = i1(1);
else
    i1 =floor(N*0.8);
end


mask = (r<=i1);

x = x.*mask;
m = imfill(bwareaopen(imopen(imclearborder(imextendedmax(x,.3)),strel('disk',1)),30),'holes');

