E = linspace(0,1,1000);

nu = 1;

F = 3 * 2 * nu^6;
G = sqrt(E ./ (F .* (1 - E)));
H = 1 ./ (2 * (1 - E) .* sqrt(3 .* E .* F .* (1-E)));

Fd = 3 / 2 * E ./ (1 - E);

p = zeros(size(E));

sel = E < F ./ (1 + F);
p(sel) = H(sel) * log(2 + sqrt(3));

sel = (E > F ./ (1 + F)) & (E < 4 * F ./ (1 + 4 * F));
p(sel) = H(sel) .* log((2 + sqrt(3)) ./ (G(sel) + sqrt(G(sel).^2 - 1)));

plot(Fd,p)

%% 

nu = 2;

n = 10000;

x = rand(n);
z = rand(n);

nud = (1 + 3 * x.^2) .* z.^2 .* nu;

E = 1 ./ (1 + nud);

histogram(nud);

%%

n = 100 ;
df = 4/n;
f = (0:(n-1))*df;

p1 = (log(2 + sqrt(3)) - heaviside(f - 1) .* log(sqrt(f) + sqrt(f-1))) ./ (2 * sqrt(3 * f)) * df;

% Integrated over df
p2 = log(2+sqrt(3))/sqrt(3) * (sqrt(f+df)-sqrt(f));
p2 = p2 - heaviside(f-1) / sqrt(3) .* ((sqrt(f+df).*log(sqrt(f+df)+sqrt(f+df-1))-sqrt(f+df-1)) - (sqrt(f).*log(sqrt(f)+sqrt(f-1))-sqrt(f-1)));

sum(p2.*f)

plot(f,p1/df)
hold on


df = f(2)-f(1);
p = log(2 + sqrt(3)) / sqrt(3) * (sqrt(f+df) - sqrt(f));
p = p - heaviside(f - 1) .* ((sqrt(f+df).*log(sqrt(f+df)+sqrt(f+df-1))-sqrt(f+df-1)) - ...
                             (sqrt(f).*log(sqrt(f)+sqrt(f-1))-sqrt(f-1))) / sqrt(3);
                        
plot(f,p)
    

%%


G = 1.2;
x = linspace(0,1,1000);
z = G ./ sqrt(1 + 3 * x.^2);
plot(x,z);
ylim([0,1])


%%

x = linspace(0,10,1000);
y = 1./sqrt(x) .* erf(sqrt(x));
plot(x,y)

%% 

x = linspace(1,4,1000);
y = -log(sqrt(x)-sqrt(x-1))./sqrt(x);
plot(x,y)