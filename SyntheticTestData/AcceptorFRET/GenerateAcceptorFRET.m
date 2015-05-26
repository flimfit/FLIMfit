function GenerateAcceptorFRET

t = (0:1:12500)';
n_chan = 2;
irf = normpdf(t,2000,200);
decay_fcn = @(tau,t) (exp(-t/tau));




sel = mod(t,25) == 0;
decay = decay(sel,:);
irf = irf(sel);
irf = irf / sum(irf);

t = t(sel);

sel = t > 0;

t_d = t(sel);
decay = decay(sel,:);



function decay = FRET()

donor_ch_factors = [2 1];
acceptor_ch_factors = [1 2];

    
A = 1;

tauD = 3000;
tauA = 4000;
tauT = 4000;

kt = 1/tauT;
ka = 1/tauA;
kd = 1/tauD;

tauF = 1/(kt+kd);
a_star = kt/(kd+kt-ka);

decay = zeros(length(t),n_chan);
decay(:,1) = decay_fcn(tauF,t);
decay(:,2) = A * a_star * (-decay_fcn(tauF,t) + decay_fcn(tauA,t));

for i=1:n_chan
    d = conv(decay(:,i),irf);
    decay(:,i) = d(1:length(t));
end

decay = decay * 1e5;
decay = poissrnd(decay);

end

figure(2)
plot(t_d,decay,'o')


csvwrite('acceptor/acceptor-fret.csv',[t_d decay]);
csvwrite('acceptor-fret-irf.csv',[t irf irf]);