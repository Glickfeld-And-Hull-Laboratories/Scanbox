function k = sbxkappa(img)

% compute local curvature at the center of the image

N = (size(img,1)-1)/2;
s = N/2.5;
c = N+1;
[xx,yy] = meshgrid(-N:N,-N:N);

hx = -(xx/s^2).*exp(-(xx.^2+yy.^2)/(2*s^2));
hxx = (xx.^2-s^2)/s^4 .* exp(-(xx.^2+yy.^2)/(2*s^2));
hxy = (xx.*yy)/s^4 .* exp(-(xx.^2+yy.^2)/(2*s^2));

hy = rot90(hx);
hyy = rot90(hxx);

Fy = sum(hy(:).*img(:));
Fx = sum(hx(:).*img(:));
Fxy = sum(hxy(:).*img(:));
Fxx = sum(hxx(:).*img(:));
Fyy = sum(hyy(:).*img(:));

k = ([-Fy Fx] * [Fxx Fxy; Fxy Fyy] * [-Fy Fx]') / (Fx^2+Fy^2)^(3/2);

