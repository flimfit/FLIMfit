function kf = make_random_kappa_factor(sz)
f = linspace(0,4,1000);
f = f(2:end);
pdf = (log(2 + sqrt(3)) - heaviside(f - 1) .* log(sqrt(f) + sqrt(f-1))) ./ (2 * sqrt(3 * f));
pdf = pdf / sum(pdf);
cdf = cumsum(pdf);

f(1) = 0;

[cdf,mask] = unique(cdf);
f = f(mask);

f = [0 f];
cdf = [0 cdf];

x = rand(sz);
kf = interp1(cdf, f, x);