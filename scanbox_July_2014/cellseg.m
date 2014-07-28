function s = cellseg(x)


x = filter2(fspecial('gauss',3,1),double(x),'valid');

x = (x-min(x(:)))/(max(x(:))-min(x(:)));

N = (size(x,1)-1)/2;

[xx,yy]=meshgrid(-N:N,-N:N);
[fx,fy] = gradient(x);

r = sqrt(xx.^2+yy.^2);

th = linspace(0,2*pi,50);

for(i=1:ceil(max(r(:))))
    idx = find(r(:)>i-1 & r(:)<=i);
    m(i) = mean(x(idx));
end

rhat = min(find(m>min(m)+0.9*(max(m)-min(m))));
rhat = max(rhat,10);
rhat = min(rhat,20);

rhat = 6; % picking radius.... for x1

p = rhat*exp(1i*th);  % default initial radius

px = real(p);
py = imag(p);

% iteration deformable snake

delta = 0.05;
for(i=1:400)
    Fx = diag(fx(N+1+round(py),N+1+round(px)))';
    Fy = diag(fy(N+1+round(py),N+1+round(px)))';
    px = px +delta*Fx;
    py = py +delta*Fy;
end

m = full(sparse(N+1+round(py),N+1+round(px),1,size(x,1),size(x,2)));
m = (m>0);

s.img = x;
s.px = px;
s.py = py;

if(sum(m(:))>0)
    m = imclose(m,strel('disk',1));
    m = imdilate(m,strel('disk',1));
    ins = (imfill(m,'holes')-m) == 1;
    
    s.mask = imfill(m,8,'holes');
    
%     if(mean(x(m))<1.1*mean(x(ins)))
%         s.mask = imfill(m,'holes');
%     else
%         s.mask = m;
%     end
   
    %s.mask = bwareaopen(imfill(m .* (s.img>p1),'holes'),p2); % fill holes?
else
    s.mask = m;
end



