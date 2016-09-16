function r = sbxmoments(r)

r.mean = r.m{1};
r.var =  r.m{2}/r.n;
r.skew = sqrt(r.n) * r.m{3} ./ r.m{2}.^(3/2);
r.kurt = r.n * r.m{4} ./ r.m{2}.^2 - 3;
