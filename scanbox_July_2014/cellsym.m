function r = cellsym(x)

x = double(x);
x = x - mean(x(:));
N = (size(x,1)-1)/2;

[xx,yy] = meshgrid(-N:N,-N:N);
r = sqrt(xx.^2+yy.^2);
th = 0:45:315;

m = zeros(size(x));
xm = x.*msk;

err = m-xm;
r = sum(err(:).^2) / sum(xm(:).^2);
