N = 256;
t = (0:(N-1))' / N * 20e3;
g = normpdf(t,4000,900);

ex = 3 * exp(-t/1000);
ex = ex + 5 * exp(-t/3000);

ex = ex * 1e5;
ex(t<0) = 0;

f = conv(ex,g,'full');
f = f(1:length(t));

fact = norm(f);

f_noise = poissrnd(f)/fact;
f = f/fact;

subplot(3,1,1);
plot(t,g);
subplot(3,1,2);
plot(t,ex);
subplot(3,1,3);
plot(t,f);
hold on
plot(t,f_noise,'r');
hold off;

%tau = phase_plane_estimation(t,g,f_noise,1);
%disp(tau')

tau = phase_plane_estimation(t,g,f_noise,2);
disp(tau')

%tau = phase_plane_estimation(t,g,f_noise,3);
%disp(tau./[3000; 5000]')
