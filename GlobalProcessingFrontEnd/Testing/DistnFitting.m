t = 1:20:5e4;

irf = zeros(size(t));
irf(200:300) = 1;

taut = 1000:100:4000;
betat = normpdf(taut,6000,3000);

decay = 0;
for i=1:length(taut)
   
    decay = decay + exp(-t/taut(i)) * betat(i); 
    
end

y = conv(irf,decay);

y = y / max(y);

y = y * 10e3;

y = poissrnd(y);

y = y(1:length(t));

subplot(2,1,1)
plot(t,[y;decay;irf])
%plot(taut,betat);

tau=100:100:10000;
n = length(tau);

C = []; 

for i=1:n
   
    d = exp(-t/tau(i));
    d = conv(irf,d);
    d = d(1:length(t));
    
    C = [C; d];
    
end

lb = zeros(size(tau));
options = optimset('Diagnostics','off','LargeScale','off','MaxIter',400);
x = lsqlin(C',y',[],[],[],[],lb,[],lb,options);
subplot(2,1,2)
plot(tau,x)
