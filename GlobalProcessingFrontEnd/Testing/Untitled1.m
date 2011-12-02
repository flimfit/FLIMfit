t = 1:100:10000;
f1 = exp(-t/1000);
s1 = sum(f1);

f2 = exp(-t/500);
s2 = sum(f2);

A = 0.4;

nr = 1000;

est_1 = zeros(1,nr);
est_2 = zeros(1,nr);

%matlabpool(4)
for k=1:nr

    g = (A * f1 + (1-A) * f2);
    g = g/sum(g);

    g = 300 * g;
    g = uint16(g);
    g = imnoise(g,'poisson');
    g = double(g);

    a = 0:0.01:1;
    l = zeros(size(a));
    
    xx = g/[f1; f2];
    
    est_1(k) = xx(1)/(sum(xx));
    
    for i=1:length(a)
        p = (a(i) * f1 + (1-a(i)) * f2) ./ (a(i) * s1 + (1-a(i)) * s2);

        n = (f2 - f1)./(s2 - s1) + (f2 * s1 - f1 * s2)/(s2-s1)^2 .* (log(f1.*f2));

        l(i) = sum( g.* log( p ./ n ) );


        %l(i) = sum(g .* ( a(i) .* f1 + (1-a(i)) .* f2 ) ./ ( 0.5 * ( f1 + f2 )));
    end

    l = abs(l);
    l = l/max(l);
    l = exp(l);
    
    max(l)
    
    subplot(1,2,1)
    plot(t,g)

    subplot(1,2,2)
    plot(a,l)
    %ylim([max(l)*0.99 max(l)])
    xlim([0 1])
    
    pause(2)
    [~,idx] = max(l);
    
    est_2(k) = a(idx);
    
end

disp(['A_1 = ' num2str(mean(est_1)) '+/-' num2str(std(est_1))]);
disp(['A_2 = ' num2str(mean(est_2)) '+/-' num2str(std(est_2))]);
disp(' ');


d1 = ksdensity(est_1,a);
d2 = ksdensity(est_2,a);


plot(a,[d1; d2])
xlim([0 1]);
